module SwarmClusterCliOpe
  class SwarmCommand < DockerCommand

    def initialize

    end

    # @return [SwarmClusterCliOpe::ShellCommandResponse]
    def ls
      command do |cmd|
        cmd.add("stack ls")
      end.execute
    end

  end
end