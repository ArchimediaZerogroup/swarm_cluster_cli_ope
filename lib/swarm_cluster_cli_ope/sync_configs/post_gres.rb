module SwarmClusterCliOpe
  module SyncConfigs
    class PostGres < BaseDatabase

      # @return [TrueClass, FalseClass]
      def pull
        resume('pull')

        dump_cmd = dump_cmd(remote.username, remote.password, remote.database_name)
        logger.info{ "DUMP  COMMAND: #{dump_cmd.join(' ')}"}
        if yes?("Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          container.exec("bash -c '#{dump_cmd.join(' ')}' > #{tmp_file}")
          local_container.copy_in(tmp_file, tmp_file)

          # drop old db and recreate
          drop_cmd = drop_cmd(local.username, local.password, local.database_name)
          logger.info{ "DROP  COMMAND: #{drop_cmd.join(' ')}"}
          local_container.exec("bash -c '#{drop_cmd.join(' ')}'")
          create_cmd = create_cmd(local.username, local.password, local.database_name)
          logger.info{ "CREATE COMMAND: #{create_cmd.join(' ')}"}
          local_container.exec("bash -c '#{create_cmd.join(' ')}'")

          restore_cmd = restore_cmd(local.username, local.password, local.database_name, tmp_file)
          logger.info{ "RESTORE COMMAND: #{restore_cmd.join(' ')}"}
          local_container.exec("bash -c '#{restore_cmd.join(' ')}'")
        end
        true
      end

      # @return [TrueClass, FalseClass]
      def push
        resume('PUSH')

        dump_cmd = dump_cmd(local.username, local.password, local.database_name)
        say "DUMP COMMAND: #{dump_cmd.join(' ')}"
        if yes?("ATTENZIONE !!!!!!PUSH!!!!! - Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          local_container.exec("bash -c '#{dump_cmd.join(' ')}' > #{tmp_file}")
          container.copy_in(tmp_file, tmp_file)

          # drop old db and recreate
          drop_cmd = drop_cmd(remote.username, remote.password, remote.database_name)
          logger.info{ "DROP  COMMAND: #{drop_cmd.join(' ')}"}
          container.exec("bash -c '#{drop_cmd.join(' ')}'")

          create_cmd = create_cmd(remote.username, remote.password, remote.database_name)
          logger.info{ "CREATE COMMAND: #{create_cmd.join(' ')}"}
          container.exec("bash -c '#{create_cmd.join(' ')}'")

          restore_cmd = restore_cmd(remote.username, remote.password, remote.database_name, tmp_file)
          say "RESTORE COMMAND: #{restore_cmd.join(' ')}"
          container.exec("bash -c '#{restore_cmd.join(' ')}'")
        end
        true
      end

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < BaseDatabase::EnvConfigs

        define_cfgs :database_name, default_env: "POSTGRES_DB", configuration_name: :database_name
        define_cfgs :username, default_env: "POSTGRES_USER", configuration_name: :pg_user, default_value: 'postgres'
        define_cfgs :password, default_env: "POSTGRES_PASSWORD", configuration_name: :pg_password

      end

      private

      def create_cmd(username, password, database_name)
        create_cmd = []
        create_cmd << "PGPASSWORD=\"#{password}\""
        create_cmd << 'createdb'
        create_cmd << "--username=#{username}"
        create_cmd << database_name
      end

      def drop_cmd(username, password, database_name)
        drop_cmd = []
        drop_cmd << "PGPASSWORD=\"#{password}\""
        drop_cmd << 'dropdb'
        drop_cmd << "--username=#{username}"
        drop_cmd << database_name
        drop_cmd
      end

      def restore_cmd(username, password, database_name, tmp_file)
        restore_cmd = []
        restore_cmd << "PGPASSWORD=\"#{password}\""
        restore_cmd << 'pg_restore'
        restore_cmd << '--no-acl'
        restore_cmd << '--no-owner'
        restore_cmd << "--username=#{username}"
        restore_cmd << "--dbname=#{database_name}"
        restore_cmd << tmp_file
        restore_cmd
      end

      def dump_cmd(username, password, database_name)
        dump_cmd = []
        dump_cmd << "PGPASSWORD=\"#{password}\""
        dump_cmd << 'pg_dump'
        dump_cmd << '--no-acl'
        dump_cmd << '--no-owner'
        dump_cmd << "--username=#{username}"
        dump_cmd << '--format=custom'
        dump_cmd << '--compress=9'
        dump_cmd << database_name
        dump_cmd
      end


    end
  end
end