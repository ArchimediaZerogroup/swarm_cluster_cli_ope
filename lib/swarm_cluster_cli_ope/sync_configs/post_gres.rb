module SwarmClusterCliOpe
  module SyncConfigs
    class PostGres < BaseDatabase

      def pull
        resume('pull')

        if yes?("Confermare il comando?[y,yes]")

          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          dump_cmd(remote, tmp_file)
          local.container.copy_in(tmp_file, tmp_file)

          # drop old db and recreate
          # if Gem::Version.new(local.database_version) <= Gem::Version.new("12")
          close_connections_and_drop_cmd(local)
          # else
          #   raise "DA ANALIZZARE QUANDO LA 13 disponibile....dropdb ha un force come parametro"
          # end

          create_cmd(local)

          restore_cmd(local, tmp_file)

        end
        true
      end

      # @return [TrueClass, FalseClass]
      def push
        resume('PUSH')

        if yes?("ATTENZIONE !!!!!!PUSH!!!!! - Confermare il comando?[y,yes]")

          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          dump_cmd(local, tmp_file)
          remote.container.copy_in(tmp_file, tmp_file)

          close_connections_and_drop_cmd(remote)

          create_cmd(remote)

          restore_cmd(remote, tmp_file)

        end
        true
      end

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < BaseDatabase::EnvConfigs

        define_cfgs :database_name, default_env: "POSTGRES_DB", configuration_name: :database_name
        define_cfgs :username, default_env: "POSTGRES_USER", configuration_name: :pg_user, default_value: 'postgres'
        define_cfgs :password, default_env: "POSTGRES_PASSWORD", configuration_name: :pg_password

        define_cfgs :database_version, default_env: "PG_MAJOR", configuration_name: :pg_version

      end

      private

      # @param [EnvConfigs] config
      def create_cmd(config)
        create_cmd = []
        create_cmd << "PGPASSWORD=\"#{config.password}\""
        create_cmd << 'createdb'
        create_cmd << "--username=#{config.username}"
        create_cmd << config.database_name

        logger.info { "CREATE COMMAND: #{create_cmd.join(' ')}" }
        config.container.exec("bash -c '#{create_cmd.join(' ')} || true'")
      end

      # @param [EnvConfigs] config
      # def drop_cmd(config)
      #   drop_cmd = []
      #   drop_cmd << "PGPASSWORD=\"#{config.password}\""
      #   drop_cmd << 'dropdb'
      #   drop_cmd << '--if-exists'
      #   drop_cmd << "--username=#{config.username}"
      #   drop_cmd << config.database_name
      #   drop_cmd
      #
      #   logger.info { "DROP  COMMAND: #{drop_cmd.join(' ')}" }
      #   config.container.exec("bash -c '#{drop_cmd.join(' ')}'")
      # end

      # @param [EnvConfigs] config
      def restore_cmd(config, tmp_file)
        restore_cmd = []
        restore_cmd << "PGPASSWORD=\"#{config.password}\""
        restore_cmd << 'pg_restore'
        restore_cmd << '--no-acl'
        restore_cmd << '--no-owner'
        restore_cmd << "--username=#{config.username}"
        restore_cmd << "--dbname=#{config.database_name}"
        restore_cmd << tmp_file
        restore_cmd

        logger.info { "RESTORE COMMAND: #{restore_cmd.join(' ')}" }
        config.container.exec("bash -c '#{restore_cmd.join(' ')}'")
      end

      # @param [EnvConfigs] config
      def dump_cmd(config, file)
        dump_cmd = []
        dump_cmd << "PGPASSWORD=\"#{config.password}\""
        dump_cmd << 'pg_dump'
        dump_cmd << '--no-acl'
        dump_cmd << '--no-owner'
        dump_cmd << "--username=#{config.username}"
        dump_cmd << '--format=custom'
        dump_cmd << '--compress=9'
        dump_cmd << config.database_name
        dump_cmd

        logger.info { "DUMP  COMMAND: #{dump_cmd.join(' ')}" }
        config.container.exec("bash -c '#{dump_cmd.join(' ')}' > #{file}")

      end

      # @param [EnvConfigs] config
      def close_connections_and_drop_cmd(config)

        cmd = []

        if Gem::Version.new(config.database_version) >= Gem::Version.new("13")
          cmd << "export PGPASSWORD=\"#{config.password}\" &&"
          cmd << 'dropdb --force --if-exists'
          cmd << "-U #{config.username}"
          cmd << config.database_name

        else
          cmd << "export PGPASSWORD=\"#{config.password}\" &&"

          sql = []
          sql << "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname =  '\"'\"'#{config.database_name}'\"'\"' AND pid <> pg_backend_pid();;"
          sql << "DROP DATABASE IF EXISTS #{config.database_name};"

          cmd << "echo \"#{sql.join(" ")}\" "
          cmd << '|'
          cmd << 'psql'
          cmd << "-U #{config.username}"
          cmd << "postgres"

        end
        logger.info { "CLOSE CONNECTIONS COMMAND: #{cmd.join(' ')}" }
        config.container.exec("bash -c '#{cmd.join(' ')}'")
      end

      # quello che fa capistrano quando copia in locale - utenze inventate
      # gzip -d cortobio_production_new_2020-09-10-171742.sql.gz  &&
      #   PGPASSWORD='root' psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'development' AND pid <> pg_backend_pid();;"  -U root  -h 0.0.0.0  -p 32790  development;
      # PGPASSWORD='root' dropdb  -U root  -h 0.0.0.0  -p 32790  development;
      # PGPASSWORD='root' createdb  -U root  -h 0.0.0.0  -p 32790  development;
      # PGPASSWORD='root' psql  -U root  -h 0.0.0.0  -p 32790  -d development < ./cortobio_production_new_2020-09-10-171742.sql

    end
  end
end