module SwarmClusterCliOpe
  class Worker < Node
    def manager?
      false
    end
  end
end