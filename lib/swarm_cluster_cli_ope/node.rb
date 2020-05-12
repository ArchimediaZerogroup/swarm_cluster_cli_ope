require 'uri'

module SwarmClusterCliOpe
  class Node
    include LoggerConcern

    #@return [String] nome del nodo
    attr_accessor :name
    #@return [String] nome da utilizzare nella parte DOCKER_HOST=CONNECTION_URI
    attr_accessor :connection_uri


    # @param [String] name
    # @param [String] connection_uri
    def initialize(name: nil, connection_uri: nil)
      @name = name
      @connection_uri = connection_uri || name
    end

    ##
    # Mi definisce se la connessione che stiamo facendo con questo nodo, la facciamo tramite SSH oppure è locale
    def is_over_ssh_uri?
      connection_uri.match?(/\Assh\:/)
    end

    ##
    # connection_uri senza la parte del protocollo
    # @return [String]
    def hostname
      URI(connection_uri).host
    end


    ##
    # Controlla se questo nodo è un manager
    # @return [TrueClass,FalseClass]
    def manager?
      info.Swarm["RemoteManagers"].collect { |n| n["NodeID"] }.include?(info.Swarm["NodeID"])
    end

    ##
    # ID univoco del nodo
    # @return [String]
    def id
      info.Swarm.NodeID
    end

    ##
    # Info del nodo da parte di docker
    # @return [OpenStruct]
    def info
      # path al file di cache
      path = Time.now.strftime("/tmp/.swarm_cluster_cli_info_cache_#{name}-%Y%m%d%H")
      if File.exist?(path)
        i = JSON.parse(File.read(path), object_class: OpenStruct)
      else
        i = Node.info(connection_uri)
        #mi salvo in cache le info scaricate
        File.open(path, "w") do |f|
          f.write(i.to_h.to_json)
        end
      end

      i
    end

    ##
    # Ritorna le info base di un nodo
    def self.info(connection_uri)
      command = Commands::Base.new
      command.docker_host = "DOCKER_HOST=#{connection_uri}"
      result = command.command do |cmd|
        cmd.add("info")
      end.execute.result.first
      result
    end

  end
end