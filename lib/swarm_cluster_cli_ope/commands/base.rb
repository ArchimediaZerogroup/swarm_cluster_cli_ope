module SwarmClusterCliOpe
  module Commands
    class Base
      include LoggerConcern
      include ConfigurationConcern

      #@return [String] Identifivo per potersi collegare
      attr_accessor :docker_host

      #@return [Array<String>] elenco di comandi da aggiungere in coda al comando lanciato
      attr_accessor :base_suffix_command

      def initialize(connection_uri: nil, base_suffix_command: ["--format=\"{{json .}}\""])
        if connection_uri
          if connection_uri.blank?
            @docker_host = "DOCKER_HOST=" # casistica di sviluppo, in cui l'host viene mappato localmente
          else
            @docker_host = "DOCKER_HOST=#{connection_uri}"
          end
        end
        @base_suffix_command = base_suffix_command
      end


      def docker_host
        return @docker_host unless @docker_host.nil?
        @docker_host = if Configuration.exist_base?
                         "DOCKER_HOST=#{cfgs.managers.first.connection_uri}"
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


    end
  end
end