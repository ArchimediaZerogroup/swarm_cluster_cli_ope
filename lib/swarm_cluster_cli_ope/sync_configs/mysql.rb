module SwarmClusterCliOpe
  module SyncConfigs
    class Mysql < Base

      # @return [TrueClass, FalseClass]
      def pull
        resume
        # container.exec("echo $MYSQL_ROOT_PASSWORD")
        # container.exec("env")
        # container.exec("echo $MYSQL_ROOT_PASSWORD && mysqldump #{database_name} -u root --password=$MYSQL_ROOT_PASSWORD")
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::DbConfigs]
      def remote
        DbConfigs.new(self, @configs[:configs][:remote] || {}, container)
      end

      # @return [SwarmClusterCliOpe::SyncConfigs::Mysql::DbConfigs]
      def local
        DbConfigs.new(self, @configs[:configs][:local] || {}, local_container)
      end


      ##
      # Classe interna che rappresenta le configurazioni
      # del db lette
      class DbConfigs


        # @param [Hash] configs
        # @param [SwarmClusterCliOpe::SyncConfigs::Mysql] sync_configs
        # @param [Object] container Istanza container su cui la
        def initialize(sync_configs, configs, container)
          @configs = configs
          @sync_configs = sync_configs
          @container = container
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
          @env ||= @container.exec("env").raw_result[:stdout].split("\n").collect{|v| v.split('=') }.to_h
        end

        def find_env_file_variable(env_var)
          if env_var.match?(/_FILE$/)
            # dobbiamo controllare la presenza del file e salvarci il contenuto
            nome_file =  env[env_var.to_s]
            @container.exec("cat #{nome_file}").raw_result[:stdout]
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
              service_name: # {local.service_name}
              database_name: # {local.database_name}
              mysql_user: # {local.mysql_user}
              mysql_password: # {local.mysql_password}
            remote:
              service_name: #{remote.service_name}
              database_name: #{remote.database_name}
              mysql_user: #{remote.mysql_user}
              mysql_password: #{remote.mysql_password}"

        end
      end

      private

      def local_container

      end

    end
  end
end