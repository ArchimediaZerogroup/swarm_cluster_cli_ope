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

    NoBaseConfigurations = Class.new(Error)

    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      return @_managers if @_managers
      @_managers = self.class.merged_configurations[:managers].collect { |m| Manager.new(m) }
    end

    ##
    # Lista di managers da assegnare alle configurazioni
    #
    # @param [Array<SwarmClusterCliOpe::Manager>] mngs
    # @return [Configuration]
    def managers=(mngs)
      @_managers = mngs
      self
    end

    ##
    # Lista dei Worker
    # @return [Array<Worker>]
    def workers
      @_workers ||= []
    end


    ##
    # Lista di managers da assegnare alle configurazioni
    #
    # @param [Array<SwarmClusterCliOpe::Manager>] mngs
    # @return [Configuration]
    def workers=(objs)
      @_workers = objs
      self
    end

    ##
    # Lista di tutti i nodi del cluster
    #
    # @return [Array<SwarmClusterCliOpe::Worker,SwamClusterCliOpe::Manager>]
    def nodes
      workers + managers
    end

    # @return [String,NilClass] nome dello stack del progetto se configurato
    def stack_name
      return self.class.merged_configurations[:stack_name] if self.class.merged_configurations.key?(:stack_name)
    end

    ##
    # Livello di logging
    # @return [Integer]
    def logger_level
      "3"
    end

    def development_mode?
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
                  managers: managers.collect(&:name)
                }.to_json)
      end
    end

    # @return [String] path to base home configurations
    def self.base_cfg_path
      File.join(ENV['HOME'], '.swarm_cluster', 'config.json')
    end

    private

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

        if File.exist?(File.join(folder, '.swarm_cluster_project'))
          project_file = File.join(folder, '.swarm_cluster_project')
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
