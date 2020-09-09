module SwarmClusterCliOpe
  module SyncConfigs
    class Mysql < Base

      # @return [TrueClass, FalseClass]
      def pull
        resume('pull')
        if yes?("Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          container.exec("bash -c 'mysqldump  -u #{remote.mysql_user} --password=#{remote.mysql_password} #{remote.database_name} | gzip -c -f' > #{tmp_file}")
          local_container.copy_in(tmp_file, tmp_file)
          local_container.exec("bash -c 'zcat #{tmp_file} | mysql  -u #{local.mysql_user} --password=#{local.mysql_password} #{local.database_name}'")
        end
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::EnvConfigs]
      def remote
        EnvConfigs.new(self, @configs[:configs][:remote] || {}, -> { container })
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::EnvConfigs]
      def local
        EnvConfigs.new(self, @configs[:configs][:local] || {}, -> { local_container })
      end


      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < SwarmClusterCliOpe::SyncConfigs::EnvConfigs

        define_cfgs :database_name, default: "MYSQL_DATABASE"
        define_cfgs :mysql_user, default: "MYSQL_USER", configuration_name: :mysql_user_env
        define_cfgs :mysql_password, default: "MYSQL_PASSWORD", configuration_name: :mysql_password_env

      end


      ##
      # Funzione che ricapitola le informazioni utilizzate per eseguire l'operazione
      def resume(direction)
        logger.info do
          "RESUME - #{direction}
            service: #{service}
            local:
              service_name: #{local.service_name}
              database_name: #{local.database_name}
              mysql_user: #{local.mysql_user}
              mysql_password: #{local.mysql_password}
            remote:
              service_name: #{remote.service_name}
              database_name: #{remote.database_name}
              mysql_user: #{remote.mysql_user}
              mysql_password: #{remote.mysql_password}"

        end
      end

      private

      def local_container
        # il nome dello stack del compose usiamo come standard il nome della cartella, come lo fà già composer di default
        Models::ComposeContainer.find_by_service_name(local.service_name, stack_name: @stack_cfgs.local_compose_project_name)
      end

    end
  end
end