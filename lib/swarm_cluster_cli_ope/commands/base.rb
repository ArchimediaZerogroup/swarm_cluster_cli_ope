module SwarmClusterCliOpe
  module Commands
    class Base
      include LoggerConcern

      #@return [String] Identifivo per potersi collegare
      attr_accessor :docker_host
      ##
      # Configurazioni standard
      # @return [SwarmClusterCliOpe::Configuration]
      def cfgs
        Configuration.instance
      end

      def docker_host
        return @docker_host unless @docker_host.nil?
        @docker_host = if Configuration.exist_base?
                         "DOCKER_HOST=ssh://#{cfgs.managers.first.connection_uri}"
                       end
      end

      ##
      # Aggiunge al blocco passato di comandi, i comandi standard iniziali
      # @return [SwarmClusterCliOpe::ShellCommandExecution]
      def command
        cmd = ShellCommandExecution.new(base_prefix_command)
        yield cmd if block_given?
        cmd.add(*base_suffix_command)
      end

      ##Esegue l'inspect sul componente
      # @param [String] id
      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def docker_inspect(id)
        command do |cmd|
          cmd.add(" #{self.class.object_identifier} inspect #{id}")
        end.execute
      end

      ##
      # Ritorna il nome identificativo dell'elemento all'interno di docker: container,service,stack ecc..
      # @return [String]
      def self.object_identifier
        self.name.demodulize.downcase
      end

      private

      def base_prefix_command
        if cfgs.development_mode?
          ["docker"]
        else
          [docker_host, "docker"]
        end
      end

      def base_suffix_command
        ["--format=\"{{json .}}\""]
      end

    end
  end
end