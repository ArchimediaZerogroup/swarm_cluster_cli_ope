module SwarmClusterCliOpe
  module Models
    class Service < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id


      def self.all(stack_name: nil)
        Commands::ServiceCommand.new.ls(stack_name: stack_name).result(object_class: Service)
      end

    end
  end
end
