module SwarmClusterCliOpe
  module SyncConfigs
    class Mysql < BaseDatabase

      # @return [TrueClass, FalseClass]
      def pull
        resume('pull')
        if yes?("Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"

          #--ignore-table=bkw_ecospazio.gps_events
          remote_authentication = "-u #{remote.username} --password=#{remote.password}"
          dump_command = "mysqldump #{remote_authentication}"
          remote.excluded_tables_data.each do |t|
            dump_command << " --ignore-table=#{remote.database_name}.#{t}"
          end
          dump_command << " #{remote.database_name}"
          dump_command << " > /tmp/export.sql"
          # eseguiamo il backup dello schema per le tabelle elencate
          remote.excluded_tables_data.each do |t|
            dump_command << " &&"
            dump_command << " mysqldump #{remote_authentication}"
            dump_command << " --no-data #{remote.database_name} #{t} >> /tmp/export.sql"
          end

          container.exec("bash -c '#{dump_command} && cat /tmp/export.sql | gzip -c -f' > #{tmp_file}")
          local_container.copy_in(tmp_file, tmp_file)
          local_authentication = "-u #{local.username} --password=#{local.password}"

          command = []
          command << "bash -c '"

          command << "mysql #{local_authentication} -e \"DROP DATABASE IF EXISTS #{local.database_name};CREATE DATABASE  #{local.database_name}\""

          command << "&&"

          command << "zcat #{tmp_file}"
          command << "|"
          command << "mysql #{local_authentication} #{local.database_name}"

          command << "'"

          local_container.exec(command.join " ")
        end
        true
      end

      # @return [TrueClass, FalseClass]
      def push
        resume('PUSH')
        if yes?("ATTENZIONE !!!!!!PUSH!!!!! - Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          local_container.exec("bash -c 'mysqldump  -u #{local.username} --password=#{local.password} #{local.database_name} | gzip -c -f' > #{tmp_file}")
          container.copy_in(tmp_file, tmp_file)
          container.exec("bash -c 'zcat #{tmp_file} | mysql  -u #{remote.username} --password=#{remote.password} #{remote.database_name}'")
        end
        true
      end

      def resume(direction)
        super

        puts "excluded_tables: #{remote.excluded_tables_data.join(",")}"
      end

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < BaseDatabase::EnvConfigs

        define_cfgs :database_name, default_env: "MYSQL_DATABASE", configuration_name: :database_name
        define_cfgs :username, default_env: "MYSQL_USER", configuration_name: :mysql_user, default_value: 'root'
        define_cfgs :password, default_env: "MYSQL_PASSWORD", configuration_name: :mysql_password, default_value: 'root'

        define_cfgs :database_version, default_env: "MYSQL_MAJOR", configuration_name: :mysql_version

        define_cfgs :excluded_tables_data, default_value: [], configuration_name: :excluded_tables_data

      end

    end
  end
end