require "singleton"
module SwarmClusterCliOpe
  ##
  # Classe per la gestione delle configurazioni
  class Configuration
    include Singleton
    include LoggerConcern

    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      #FIXME con configurazioni lette dalla home
      [
        Manager.new("swarm_node_1"),
        Manager.new("swarm_node_2"),
        Manager.new("swarm_node_3")
      ]
    end

    ##
    # Lista dei Worker
    # @return [Array<Worker>]
    def workers
      []
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
      3
    end

  end
end
