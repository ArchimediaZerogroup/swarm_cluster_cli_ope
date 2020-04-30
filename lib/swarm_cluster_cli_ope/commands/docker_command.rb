module SwarmClusterCliOpe
  module Commands
    class DockerCommand
      include LoggerConcern

      ##
      # Configurazioni standard
      # @return [SwarmClusterCliOpe::Configuration]
      def cfgs
        Configuration.instance
      end


      ##
      # Aggiunge al blocco passato di comandi, i comandi standard iniziali
      # @return [SwarmClusterCliOpe::ShellCommandExecution]
      def command
        cmd = ShellCommandExecution.new(base_prefix_command)
        yield cmd if block_given?
        cmd.add(*base_suffix_command)
      end

      private

      def base_prefix_command
        ["DOCKER_HOST=ssh://#{cfgs.managers.first.name}", "docker"]
      end

      def base_suffix_command
        ["--format=\"{{json .}}\""]
      end

    end
  end
end