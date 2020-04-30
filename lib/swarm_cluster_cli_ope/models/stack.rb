module SwarmClusterCliOpe
  module Models
    class Stack < Base

      #@return [:String]
      attr_accessor :name
      #@return [String]
      attr_accessor :namespace
      #@return [Integer]
      attr_accessor :services

      # @return [Array<Stack>]
      def self.all
        Commands::SwarmCommand.new.ls.result(object_class: Stack)
      end
    end
  end
end