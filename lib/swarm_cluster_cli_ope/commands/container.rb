module SwarmClusterCliOpe
  module Commands
    class Container < Base

      def cp(src, dest)
        self.base_suffix_command = []
        command do |cmd|
          cmd.add("cp #{src} #{dest}")
        end.execute
      end

      def exec(container_id,cmd_str)
        self.base_suffix_command = []
        command do |cmd|
          cmd.add("exec #{container_id} #{cmd_str}")
        end.execute
      end

      ##
      # Esegue il ps sui container, possibile filtrare passando nome stack e/o nome servizio
      # @param [String] service_name
      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def ps(service_name: nil)
        command do |cmd|
          cmd.add("ps")
          cmd.add("--filter=\"label=com.docker.swarm.service.name=#{service_name}\"") if service_name
        end.execute
      end
    end
  end
end