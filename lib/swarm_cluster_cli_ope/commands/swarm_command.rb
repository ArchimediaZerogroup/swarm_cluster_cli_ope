module SwarmClusterCliOpe
  module Commands
    class SwarmCommand < DockerCommand

      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def ls
        command do |cmd|
          cmd.add("stack ls")
        end.execute
      end

    end
  end
end