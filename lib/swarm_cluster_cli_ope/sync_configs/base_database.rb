module SwarmClusterCliOpe
  module SyncConfigs
    class BaseDatabase < Base

      # @return [SwarmClusterCliOpe::SyncConfigs::EnvConfigs]
      def remote
        self.class::EnvConfigs.new(self, @configs.dig(:configs, :remote) || {}, -> { container })
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::EnvConfigs]
      def local
        self.class::EnvConfigs.new(self, @configs.dig(:configs, :local) || {}, -> { local_container })
      end

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < SwarmClusterCliOpe::SyncConfigs::EnvConfigs

      end

      ##
      # Funzione che ricapitola le informazioni utilizzate per eseguire l'operazione
      def resume(direction)
        puts "RESUME - #{direction}
            service: #{service}
            local:
              service_name: #{local.service_name}
              database_name: #{local.database_name}
              username: #{local.username}
              password: #{local.password}
            remote:
              service_name: #{remote.service_name}
              database_name: #{remote.database_name}
              username: #{remote.username}
              password: #{remote.password}"

      end

      private

      def local_container
        # il nome dello stack del compose usiamo come standard il nome della cartella, come lo fà già composer di default
        Models::ComposeContainer.find_by_service_name(local.service_name, stack_name: @stack_cfgs.local_compose_project_name)
      end


    end
  end
end