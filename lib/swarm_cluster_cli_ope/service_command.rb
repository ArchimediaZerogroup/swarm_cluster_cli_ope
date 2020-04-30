module SwarmClusterCliOpe
  class ServiceCommand < DockerCommand

    # @return [SwarmClusterCliOpe::ShellCommandResponse]
    def ls
      command do |cmd|
        cmd.add("service ls")
      end.execute
    end


  end
end