module SwarmClusterCliOpe
  module Models
    class ComposeContainer < Container

      # @return [SwarmClusterCliOpe::Models::ComposeContainer]
      def self.find_by_service_name(service_name, stack_name: '')
        # prima controlliamo se siamo con il vecchio sistema di docker-compose dove i nomi dei servizi venivano
        # costruiti con _ oppure se siamo nella nuova versione di docker compose dove c'è il - che fà da spaziatore
        res = nil
        ["_", "-"].each do |separatore|
          res = ShellCommandExecution.new("docker inspect #{[stack_name, service_name, "1"].compact.join(separatore)}").execute(allow_failure: true)
          break unless res.failed?
        end
        raise "Non siamo riusciti ad identificare il servizio in locale" if res.failed?
        self.new(JSON.parse(res.raw_result[:stdout]).first)
      end

      def mapped_uri_connection
        nil
      end

    end
  end
end
