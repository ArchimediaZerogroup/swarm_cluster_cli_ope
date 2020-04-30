module SwarmClusterCliOpe
  class Stack < BaseDockerModel

    #@return [:String]
    attr_accessor :name
    #@return [String]
    attr_accessor :namespace
    #@return [Integer]
    attr_accessor :services

    # @return [Array<Stack>]
    def self.all
      SwarmCommand.new.ls.result(object_class: Stack)
    end
  end
end