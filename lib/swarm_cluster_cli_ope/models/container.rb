module SwarmClusterCliOpe
  module Models
    class Container < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id
      #@return [String] nome dell'immagine
      attr_accessor :image
      #@return [String] nome dell'host in cui si trova il container
      attr_accessor :node


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
        Commands::Container.new(connection_uri: cfgs.get_node(node)).cp(src, "#{id}:#{dest}").success?
      end

      ##
      # Copia i file dal container all'esterno
      # @param [String] src sorgente da cui copiare
      # @param [String] dest destinazione a cui copiare
      def copy_out(src, dest)
        Commands::Container.new(connection_uri: cfgs.get_node(node)).cp("#{id}:#{src}", dest).success?
      end


    end
  end
end
