module SwarmClusterCliOpe
  module Models
    class Service < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id

      # @return [Array<SwarmClusterCliOpe::Service>]
      def self.all(stack_name: nil)
        Commands::Service.new.ls(stack_name: stack_name).result(object_class: Service)
      end

      # @return [SwarmClusterCliOpe::Service]
      def self.find(service_name, stack_name: nil)
        Commands::Service.new.find(service_name, stack_name: stack_name).result(object_class: Service).first
      end

      ##
      # Containers del servizio
      # @return [Array<SwarmClusterCliOpe::Container>]
      def containers
        Commands::Container.new.ps(service_name: name).result(object_class: Container)
      end

    end
  end
end
