module SwarmClusterCliOpe
  class Service < BaseDockerModel

    #@return [String]
    attr_accessor :name
    #@return [String]
    attr_accessor :id


    def self.all(stack_name: nil)
      ServiceCommand.new.ls.result(object_class: Service)
    end

  end
end