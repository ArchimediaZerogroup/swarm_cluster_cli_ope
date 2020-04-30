require "singleton"
require "fileutils"
require "json"
module SwarmClusterCliOpe
  ##
  # Classe per la gestione delle configurazioni
  class Configuration
    include Singleton
    include LoggerConcern

    NoBaseConfigurations = Class.new(Error)

    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      return @_managers if @_managers
      @_managers = self.class.read_base['managers'].collect { |m| Manager.new(m) }
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

    ##
    # Livello di logging
    # @return [Integer]
    def logger_level
      "3"
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
      JSON.parse(File.read(self.base_cfg_path))
    end

  end
end
