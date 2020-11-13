module SwarmClusterCliOpe
  ##
  # Classe Base delle configurazioni, utilizzabile per swarm e kubernetes
  class BaseConfiguration
    include Singleton
    include LoggerConcern

    #@return [String] nome dello stack con cui lavoriamo
    attr_accessor :stack_name

    #@return [String] in che enviroment siamo, altrimenti siamo nel default
    attr_accessor :environment

    NoBaseConfigurations = Class.new(Error)

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


    # @return [String] path to base home configurations
    def self.base_cfg_path
      File.join(ENV['HOME'], '.swarm_cluster', 'config.json')
    end


    ##
    # Elenco di tutte le configurazioni di sincronizzazione
    # @return [Array]
    def sync_configurations
      cfgs = merged_configurations[:sync_configs]
      return [] if cfgs.nil? or !cfgs.is_a?(Array)
      cfgs.collect do |c|

        if self.get_syncro(c[:how])
          self.get_syncro(c[:how]).new(self, c)
        end

      end.compact
    end

    ##
    # Funzione per la restituzione della classe di sincro corretta
    # @return [Class<SwarmClusterCliOpe::SyncConfigs::PostGres>, Class<SwarmClusterCliOpe::SyncConfigs::Mysql>, Class<SwarmClusterCliOpe::SyncConfigs::Rsync>, Class<SwarmClusterCliOpe::SyncConfigs::Sqlite3>, nil]
    def get_syncro(name)
      case name
      when 'sqlite3'
        SyncConfigs::Sqlite3
      when 'rsync'
        SyncConfigs::Rsync
      when 'mysql'
        SyncConfigs::Mysql
      when 'pg'
        SyncConfigs::PostGres
      else
        logger.error { "CONFIGURAIONE NON PREVISTA: #{name}" }
        nil
      end
    end

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

      configuration_version = @_merged_configurations[@environment][:version]
      if Gem::Version.new(configuration_version) > Gem::Version.new(VERSION)
        puts "WARNING: Versione del file di configurazione [#{configuration_version}] più aggiornata della gemma [#{VERSION}], eseguire upgrade
              gem update swarm_cluster_cli_ope"
        exit
      end

      evaluate_correct_command_usage(@_merged_configurations[@environment])

      @_merged_configurations[@environment]

    end


    ##
    # Si occupa del salvataggio delle configurazioni di progetto, se abbiamo lo stack_name
    def save_project_cfgs
      if stack_name
        File.open(File.join(FileUtils.pwd, self.class.cfgs_project_file_name(with_env: @environment)), "wb") do |f|
          f.write({
                    stack_name: stack_name,
                    version: VERSION
                  }.to_json)
        end
      end
    end


    ##
    # Salva le configurazioni base in HOME
    def save_base_cfgs
      FileUtils.mkdir_p(File.dirname(self.class.base_cfg_path))
      File.open(self.class.base_cfg_path, "wb") do |f|
        obj= {
          version: SwarmClusterCliOpe::VERSION,
        }
        obj = yield(obj) if block_given?

        f.write(obj.to_json)
      end
    end


    private

    ##
    # Funzione che serve per identificare se siamo nella corretta classe di configurazione e di conseguenza nel corretto
    # set di comandi di configurazione. Serve per non eseguire k8s con le vecchie impostazioni o viceversa
    def evaluate_correct_command_usage(configuration) end

    ##
    # nome del file in cui salvare le configurazioni di progetto
    # @return [String]
    # @param [nil|String] with_env nome dell'env da cercare
    def self.cfgs_project_file_name(with_env: nil)
      ".swarm_cluster_project#{with_env ? ".#{with_env}" : ""}"
    end

    ##
    # Legge le configurazioni base
    #
    # @return [Hash]
    def self.read_base
      raise NoBaseConfigurations if !exist_base? or File.size(self.base_cfg_path)==0
      JSON.parse(File.read(self.base_cfg_path)).deep_symbolize_keys
    end

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