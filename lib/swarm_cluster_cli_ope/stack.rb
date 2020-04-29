module SwarmClusterCliOpe
  class Stack

    #@return [:String]
    attr_accessor :name
    #@return [String]
    attr_accessor :namespace
    #@return [Integer]
    attr_accessor :services

    def initialize(dati)
      @name, @namespace, @services = dati["Name"], dati["Namespace"], dati["Services"]
    end

    # @return [Array<Stack>]
    def self.all
      SwarmCommand.new.ls.result(object_class: Stack)
    end
  end
end