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
        tasks.collect { |t| t.container }
      end

      ##
      # Elenco dei task del servizio
      # docker service ps SERVICE_NAME --format="{{json .}}" -f "desired-state=running"
      # @return [Array<Task>]
      def tasks
        docker_command.ps(name).result(object_class: Task)
      end

    end
  end
end
