module SwarmClusterCliOpe
  module Models
    class Container < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id
      #@return [String] nome dell'immagine
      attr_accessor :image
      #@return [Hash] labels del container
      attr_accessor :labels


      def labels=(labels)
        @labels = labels.split(",").collect { |a| a.split("=") }.collect { |a, b| [a, b] }.to_h
      end

      # @return [String] id del nodo di appartenenza
      def node_id
        labels["com.docker.swarm.node.id"]
      end

      # @return [SwarmClusterCliOpe::Models::Container]
      def self.find_by_service_name(service_name, stack_name: nil)
        all(service_name: "#{stack_name}_#{service_name}").first
      end

      def self.all(service_name: nil)
        Commands::Container.new.ps(service_name: service_name).result(object_class: Container)
      end

      ##
      # Copia i file dentro al container
      # @param [String] src sorgente da cui copiare
      # @param [String] dest destinazione a cui copiare
      def copy_in(src, dest)
        Commands::Container.new(connection_uri: mapped_uri_connection).cp(src, "#{id}:#{dest}").success?
      end

      ##
      # Copia i file dal container all'esterno
      # @param [String] src sorgente da cui copiare
      # @param [String] dest destinazione a cui copiare
      def copy_out(src, dest)
        Commands::Container.new(connection_uri: mapped_uri_connection).cp("#{id}:#{src}", dest).success?
      end

      ##
      # Ritorna il connection_uri del nodo che ospita il container
      # @return [String]
      def mapped_uri_connection
        cfgs.get_node_by_id(node_id).connection_uri
      end


    end
  end
end