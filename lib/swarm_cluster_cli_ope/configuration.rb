require "singleton"
require "fileutils"
require "json"
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

    NoBaseConfigurations = Class.new(Error)

    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      return @_managers if @_managers
      @_managers = self.nodes.select { |n| read_managers_cache_list.include?(n.name) }.collect { |c| Manager.new(name: c.name.to_s, connection_uri: c.connection_uri) }
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
      refresh_managers_cache_list unless File.exists?(swarm_manager_cache_path)
      File.read(swarm_manager_cache_path).split("\n")
    end

    ##
    # Lista di tutti i nodi del cluster
    #
    # @return [Array<SwarmClusterCliOpe::Node>]
    def nodes
      return @_nodes if @_nodes
      @_nodes = self.class.merged_configurations[:connections_maps].collect { |m, c| Node.new(name: m.to_s, connection_uri: c) }
    end

    ##
    # Lista di nodi da assegnare alle configurazioni
    #
    # @param [Array<SwarmClusterCliOpe::Node>]
    # @return [Configuration]
    def nodes=(objs)
      @_nodes = objs
      self
    end

    # @return [String,NilClass] nome dello stack del progetto se configurato
    def stack_name
      return @stack_name if @stack_name
      return nil unless self.class.exist_base?
      @stack_name = self.class.merged_configurations[:stack_name] if self.class.merged_configurations.key?(:stack_name)
    end

    ##
    # Livello di logging
    # @return [Integer]
    def logger_level
      "3"
    end

    ##
    # Siamo in sviluppo?
    # @return [TrueClass, FalseClass]
    def development_mode?
      return false unless self.class.exist_base?
      self.class.merged_configurations.key?(:dev_mode)
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
      if @stack_name
        File.open(File.join(FileUtils.pwd, self.class.cfgs_project_file_name), "wb") do |f|
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

    private

    ##
    # nome del file in cui salvare le configurazioni di progetto
    # @return [String]
    def self.cfgs_project_file_name
      '.swarm_cluster_project'
    end

    ##
    # Path al file dove salviamo la cache dei managers
    # @return [String]
    def swarm_manager_cache_path
      File.join("/tmp", ".swarm_cluster_cli_manager_cache")
    end

    ##
    # Legge le configurazioni base
    #
    # @return [Hash]
    def self.read_base
      raise NoBaseConfigurations unless exist_base?
      JSON.parse(File.read(self.base_cfg_path)).deep_symbolize_keys
    end

    ## Cerca le configurazioni di progetto e le mergia se sono presenti
    # @return [Hash]
    def self.merged_configurations
      return @_merged_configurations if @_merged_configurations
      project_file = nil
      folder = FileUtils.pwd
      loop do

        if File.exist?(File.join(folder, cfgs_project_file_name))
          project_file = File.join(folder, cfgs_project_file_name)
        end

        break unless project_file.nil?
        break if folder == '/'
        folder = File.expand_path("..", folder)
      end

      project_cfgs = {}
      unless project_file.nil?
        project_cfgs = JSON.parse(File.read(project_file)).deep_symbolize_keys
      end

      @_merged_configurations = read_base.merge(project_cfgs)
    end

  end
end
