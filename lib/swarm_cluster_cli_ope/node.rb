module SwarmClusterCliOpe
  class Node
    include LoggerConcern

    #@return [String] nome del nodo
    attr_accessor :name
    #@return [String] nome da utilizzare nella parte DOCKER_HOST=ssh://NOME_QUA
    attr_accessor :connection_uri


    # @param [String] name
    # @param [String] connection_uri
    def initialize(name: nil, connection_uri: nil)
      @name = name
      @connection_uri = connection_uri || name
    end


    ##
    # Controlla se questo nodo è un manager
    # @return [TrueClass,FalseClass]
    def manager?
      infos = Node.info(connection_uri)
      infos.Swarm["RemoteManagers"].collect { |n| n["NodeID"] }.include?(infos.Swarm["NodeID"])
    end

    ##
    # Ritorna le info base di un nodo
    def self.info(connection_uri)
      command = Commands::Base.new
      command.docker_host = "DOCKER_HOST=ssh://#{connection_uri}"
      result = command.command do |cmd|
        cmd.add("info")
      end.execute.result.first
      result
    end

  end
end