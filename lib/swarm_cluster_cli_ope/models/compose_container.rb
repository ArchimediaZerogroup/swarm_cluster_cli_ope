module SwarmClusterCliOpe
  module Models
    class ComposeContainer < Container

      # @return [SwarmClusterCliOpe::Models::ComposeContainer]
      def self.find_by_service_name(service_name, stack_name: '')
        res = ShellCommandExecution.new("docker inspect #{[stack_name, service_name, "1"].compact.join("_".strip)}").execute
        self.new(JSON.parse(res.raw_result[:stdout]).first)
      end

      def mapped_uri_connection
        nil
      end

    end
  end
end
