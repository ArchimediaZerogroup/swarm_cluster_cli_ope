module SwarmClusterCliOpe
  module Models
    class Service < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id


      def self.all(stack_name: nil)
        Commands::Service.new.ls(stack_name: stack_name).result(object_class: Service)
      end

      def self.find(service_name, stack_name: nil)
        Commands::Service.new.find(service_name, stack_name: stack_name).result(object_class: Service).first
      end
  end
end
