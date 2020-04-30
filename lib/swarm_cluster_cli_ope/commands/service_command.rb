module SwarmClusterCliOpe
  module Commands
    class ServiceCommand < DockerCommand

      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      # @param [String] stack_name nome dello stack da filtrare
      def ls(stack_name: nil)
        command do |cmd|
          cmd.add("service ls")
          cmd.add("--filter=\"label=com.docker.stack.namespace=#{stack_name}\"") if stack_name
        end.execute
      end


    end
  end
end