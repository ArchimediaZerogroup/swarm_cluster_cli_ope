module SwarmClusterCliOpe
  module SyncConfigs
    class Mysql < Base

      # @return [TrueClass, FalseClass]
      def pull
        resume
        tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
        container.exec("bash -c 'mysqldump  -u #{remote.mysql_user} --password=#{remote.mysql_password} #{remote.database_name} | gzip -c -f' > #{tmp_file}")
        local_container.copy_in(tmp_file, tmp_file)
        local_container.exec("bash -c 'zcat #{tmp_file} | mysql  -u #{local.mysql_user} --password=#{local.mysql_password} #{local.database_name}'")
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::DbConfigs]
      def remote
        DbConfigs.new(self, @configs[:configs][:remote] || {}, -> { container })
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::DbConfigs]
      def local
        DbConfigs.new(self, @configs[:configs][:local] || {}, -> { local_container })
      end


      ##
      # Classe interna che rappresenta le configurazioni
      # del db lette
      class DbConfigs


        # @param [Hash] configs
        # @param [SwarmClusterCliOpe::SyncConfigs::Mysql] sync_configs
        # @param [Lambda] lambda che ritorna il container Istanza container su cui la
        def initialize(sync_configs, configs, container)
          @configs = configs
          @sync_configs = sync_configs
          @lambda_container = container
        end

        ##
        # Metodo che richiama la lambda della generazione del container al momento che ne
        # è proprio necessario
        def container
          @container ||= @lambda_container.call
        end

        # @return [String]
        def database_name
          @configs[:database_name]

          return @database_name if @database_name
          env_var = @configs[:database_name] || "MYSQL_DATABASE"
          @database_name = find_env_file_variable(env_var)
        end

        # @return [String]
        def mysql_user
          return @mysql_user if @mysql_user
          env_var = @configs[:mysql_user_env] || "MYSQL_USER"
          @mysql_user = find_env_file_variable(env_var)
        end

        # @return [String]
        def mysql_password
          return @mysql_password if @mysql_password
          env_var = @configs[:mysql_password_env] || "MYSQL_PASSWORD"
          @mysql_password = find_env_file_variable(env_var)
        end

        # @return [String]
        def service_name
          @configs[:service] || @sync_configs.service
        end


        private

        ##
        # Estrae l'env dal container e ne tiene in memoria una copia, in modo da non fare multiple chiamate
        def env
          @env ||= container.exec("env").raw_result[:stdout].split("\n").collect { |v| v.split('=') }.to_h
        end

        def find_env_file_variable(env_var)
          if env_var.match?(/_FILE$/)
            # dobbiamo controllare la presenza del file e salvarci il contenuto
            nome_file = env[env_var.to_s]
            container.exec("cat #{nome_file}").raw_result[:stdout]
          else
            # env normale, dobbiamo ricavarlo dal container
            env[env_var.to_s]
          end
        end


      end


      ##
      # Funzione che ricapitola le informazioni utilizzate per eseguire l'operazione
      def resume
        logger.info do
          "RESUME
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