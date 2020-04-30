module SwarmClusterCliOpe
  module Commands
    class Swarm < Base

      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def ls
        command do |cmd|
          cmd.add("stack ls")
        end.execute
      end

    end
  end
end