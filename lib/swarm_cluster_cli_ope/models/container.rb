module SwarmClusterCliOpe
  module Models
    class Container < Base

      #@return [String]
      attr_accessor :name
      #@return [String] id del container
      attr_accessor :id
      #@return [String] nome dell'immagine
      attr_accessor :image
      #@return [Hash] labels del container
      attr_accessor :labels


      def labels=(labels)
        @labels = labels.split(",").collect { |a| a.split("=") }.collect { |a, b| [a, b] }.to_h
      end
      ##
      # Può essere che riceva dei valori dal config, tipo quando facciamo inspect
      def config=(config)
        @labels = config["Labels"]
      end

      # @return [String] id del nodo di appartenenza
      def node_id
        labels["com.docker.swarm.node.id"]
      end

      # @return [SwarmClusterCliOpe::Models::Container]
      def self.find_by_service_name(service_name, stack_name: nil)
        Service.find(service_name,stack_name:stack_name).containers.first
      end

      def self.all(service_name: nil)
        Commands::Container.new.ps(service_name: service_name).result(object_class: Container)
      end

      ##
      # Copia i file dentro al container
      # @param [String] src sorgente da cui copiare
      # @param [String] dest destinazione a cui copiare
      def copy_in(src, dest)
        docker_command.cp(src, "#{id}:#{dest}").success?
      end

      ##
      # Copia i file dal container all'esterno
      # @param [String] src sorgente da cui copiare
      # @param [String] dest destinazione a cui copiare
      def copy_out(src, dest)
        docker_command.cp("#{id}:#{src}", dest).success?
      end

      ##
      # Esegue il comando passato
      def exec(cmd)
        docker_command.exec(id, cmd)
      end

      ##
      # Ritorna il connection_uri del nodo che ospita il container
      # @return [String]
      def mapped_uri_connection
        node.connection_uri
      end

      ##
      # Elenco dei volumi mappato
      # @return [Array<MappedVolume>]
      def mapped_volumes
        docker_inspect.Mounts.collect { |v| MappedVolume.new(v, container: self) }
      end

      ##
      # Ritorna il nodo dello swarm che contiene questo container
      # @return [SwarmClusterCliOpe::Node]
      def node
        cfgs.get_node_by_id(node_id)
      end


    end
  end
end
