module SwarmClusterCliOpe
  module Models
    class Task < Base

      #@return [String]
      attr_accessor :name
      #@return [String]
      attr_accessor :id
      #@return [String] nome dell'immagine
      attr_accessor :node


      ##
      # Estrapola il container dal task
      def container
        stack_info = docker_inspect

        cmd = Commands::Container.new(connection_uri: cfgs.get_node_by_id(stack_info.NodeID).connection_uri)
        container = cmd.docker_inspect(stack_info.Status["ContainerStatus"]["ContainerID"]).result(object_class: Container).first

        container

      end

    end
  end
end