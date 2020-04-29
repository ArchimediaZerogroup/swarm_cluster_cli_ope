module SwarmClusterCliOpe
  class Node
    include LoggerConcern

    #@return [String] nome del nodo
    attr_accessor :name

    # @param [String] name
    def initialize(name)
      @name = name
    end

  end
end