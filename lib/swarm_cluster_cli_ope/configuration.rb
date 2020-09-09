require "singleton"
require "fileutils"
require "json"
require 'digest'
require "active_support/core_ext/hash"
module SwarmClusterCliOpe
  ##
  # Classe per la gestione delle configurazioni, unisce le configurazioni di base alle configurazioni di progetto;
  # le quali sono salvate nel file di configurazione del progetto .swarm_cluster_project sottoforma di json
  # che vengono mergiate sulle configurazioni base
  class Configuration
    include Singleton
    include LoggerConcern

    #@return [String] nome dello stack con cui lavoriamo
    attr_accessor :stack_name

    #@return [String] in che enviroment siamo, altrimenti siamo nel default
    attr_accessor :environment

    NoBaseConfigurations = Class.new(Error)

    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      return @_managers if @_managers
      @_managers = self.nodes.select { |n| read_managers_cache_list.include?(n.name) }.collect { |c| Manager.new(name: c.name.to_s, connection_uri: c.connection_uri) }
    end

    ##
    # Serve per entrare nell'env corretto.
    # passando l'env, tutto quello eseguito nello yield sarà gestito in quell'env.
    # Verrà controllato quindi che esista il relativo file di configurazion
    def env(enviroment = nil)
      unless enviroment.nil?
        @environment = enviroment.to_s.to_sym
      end
      logger.info { "ENV: #{@environment ? @environment : "BASE"}" }
      yield self
      @environment = nil
    end

    ##
    # Esegue un refresh della lista dei manager, ciclando su tutti i nodi, e scrivendo in /tmp un file temporaneo con
    # con la lista dei nomi dei managers
    def refresh_managers_cache_list
      list = self.nodes.select(&:manager?).collect { |c| Manager.new(name: c.name, connection_uri: c.connection_uri) }
      File.open(swarm_manager_cache_path, "w") do |f|
        list.collect(&:name).each do |name|
          f.puts(name)
        end
      end
    end

    def read_managers_cache_list
      # TODO sarebbe da aggiornare ogni tanto, metti che uno non spegne mai il pc
      refresh_managers_cache_list unless File.exists?(swarm_manager_cache_path)
      File.read(swarm_manager_cache_path).split("\n")
    end

    ##
    # Lista di tutti i nodi del cluster
    #
    # @return [Array<SwarmClusterCliOpe::Node>]
    def nodes
      @_nodes ||= Hash.new do |hash, key|
        hash[key] = self.merged_configurations[:connections_maps].collect { |m, c| Node.new(name: m.to_s, connection_uri: c) }
      end
      @_nodes[environment]
    end

    ##
    # Lista di nodi da assegnare alle configurazioni
    #
    # @param [Array<SwarmClusterCliOpe::Node>]
    # @return [Configuration]
    def nodes=(objs)
      nodes[environment] = objs
      self
    end

    # @return [String,NilClass] nome dello stack del progetto se configurato
    def stack_name
      return nil unless self.class.exist_base?
      @stack_name ||= Hash.new do |hash, key|
        hash[key] = merged_configurations[:stack_name] if merged_configurations.key?(:stack_name)
      end
      @stack_name[environment]
    end

    ##
    # Imposta il nome dello stack
    def stack_name=(objs)
      stack_name #lo richiamo per fargli generare la variabile di classe
      @stack_name[environment] = objs
    end

    ##
    # Livello di logging
    # @return [Integer]
    def logger_level
      merged_configurations[:log_level].to_s || "0"
    rescue SwarmClusterCliOpe::Configuration::NoBaseConfigurations
      # quando andiamo in errore durante l'installazione per avere le informazioni per il logger.
      # Usiamo lo standard
      "0"
    end

    ##
    # Siamo in sviluppo?
    # @return [TrueClass, FalseClass]
    def development_mode?
      return false unless self.class.exist_base?
      merged_configurations.key?(:dev_mode)
    end

    ##
    # Controlla se esiste il file di configurazione base, nella home dell'utente
    def self.exist_base?
      File.exist?(base_cfg_path)
    end


    ##
    # Salva le configurazioni base in HOME
    def save_base_cfgs
      FileUtils.mkdir_p(File.dirname(self.class.base_cfg_path))
      File.open(self.class.base_cfg_path, "wb") do |f|
        f.write({
                  version: SwarmClusterCliOpe::VERSION,
                  connections_maps: nodes.collect { |k| [k.name, k.connection_uri] }.to_h
                }.to_json)
      end
    end

    ##
    # Si occupa del salvataggio delle configurazioni di progetto, se abbiamo lo stack_name
    def save_project_cfgs
      if stack_name
        File.open(File.join(FileUtils.pwd, self.class.cfgs_project_file_name(with_env: @environment)), "wb") do |f|
          f.write({
                    stack_name: stack_name
                  }.to_json)
        end
      end
    end

    # @return [String] path to base home configurations
    def self.base_cfg_path
      File.join(ENV['HOME'], '.swarm_cluster', 'config.json')
    end

    # @return [SwarmClusterCliOpe::Node]
    # @param [String] node nome del nodo
    def get_node(node)
      nodes.find { |c| c.name == node }
    end

    # @return [SwarmClusterCliOpe::Node]
    # @param [String] node_id
    def get_node_by_id(node_id)
      nodes.find { |c| c.id == node_id }
    end

    ##
    # Indica il nome del progetto locale compose, quella parte di nome che viene attaccata in fronte
    # ad ogni nome di servizio locale, e che come default è il nome della cartella in cui risiede
    # il docker-compose.yml file
    # @return [String]
    def local_compose_project_name
      File.basename(FileUtils.pwd)
    end

    ##
    # Elenco di tutte le configurazioni di sincronizzazione
    def sync_configurations
      merged_configurations[:sync_configs].collect do |c|

        case c[:how]
        when 'sqlite3'
          SyncConfigs::Sqlite3.new(self, c)
        when 'rsync'
          SyncConfigs::Rsync.new(self, c)
        when 'mysql'
          SyncConfigs::Mysql.new(self, c)
        else
          logger.error { "CONFIGURAIONE NON PREVISTA: #{c[:how]}" }
          nil
        end

      end.compact
    end

    private

    ##
    # nome del file in cui salvare le configurazioni di progetto
    # @return [String]
    # @param [nil|String] with_env nome dell'env da cercare
    def self.cfgs_project_file_name(with_env: nil)
      ".swarm_cluster_project#{with_env ? ".#{with_env}" : ""}"
    end

    ##
    # Path al file dove salviamo la cache dei managers, ha un TTL legato all'orario (anno-mese-giorno-ora)
    # quindi ogni ora si autoripulisce e con un md5 delle configurazioni di base
    # @return [String]
    def swarm_manager_cache_path
      md5 = Digest::MD5.hexdigest(self.merged_configurations.to_json)
      file_name = Time.now.strftime(".swarm_cluster_cli_manager_cache-%Y%m%d%H-#{md5}")
      File.join("/tmp", file_name)
    end

    ##
    # Legge le configurazioni base
    #
    # @return [Hash]
    def self.read_base
      raise NoBaseConfigurations unless exist_base?
      JSON.parse(File.read(self.base_cfg_path)).deep_symbolize_keys
    end

    public

    ## Cerca le configurazioni di progetto e le mergia se sono presenti
    # @return [Hash]
    def merged_configurations
      return @_merged_configurations[@environment] if @_merged_configurations

      @_merged_configurations = Hash.new do |hash, key|
        folder = FileUtils.pwd
        default_file = looped_file(folder, self.class.cfgs_project_file_name)
        enviroment_file = looped_file(folder, self.class.cfgs_project_file_name(with_env: key))

        project_cfgs = {}
        unless default_file.nil?
          project_cfgs = JSON.parse(File.read(default_file)).deep_symbolize_keys
        end

        unless enviroment_file.nil?
          project_cfgs.merge!(JSON.parse(File.read(enviroment_file)).deep_symbolize_keys)
        end

        hash[key] = self.class.read_base.merge(project_cfgs)
      end

      @_merged_configurations[@environment]

    end

    private

    def looped_file(start_folder, file)
      project_file = nil
      loop do

        if File.exist?(File.join(start_folder, file))
          project_file = File.join(start_folder, file)
        end

        break unless project_file.nil?
        break if start_folder == '/'
        start_folder = File.expand_path("..", start_folder)
      end

      project_file
    end

  end
end
