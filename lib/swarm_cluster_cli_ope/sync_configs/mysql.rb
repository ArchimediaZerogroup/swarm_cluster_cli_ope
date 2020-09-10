module SwarmClusterCliOpe
  module SyncConfigs
    class Mysql < BaseDatabase

      # @return [TrueClass, FalseClass]
      def pull
        resume('pull')
        if yes?("Confermare il comando?[y,yes]")
          tmp_file = "/tmp/#{Time.now.to_i}.sql.gz"
          container.exec("bash -c 'mysqldump  -u #{remote.username} --password=#{remote.password} #{remote.database_name} | gzip -c -f' > #{tmp_file}")
          local_container.copy_in(tmp_file, tmp_file)
          local_container.exec("bash -c 'zcat #{tmp_file} | mysql  -u #{local.username} --password=#{local.password} #{local.database_name}'")
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

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < BaseDatabase::EnvConfigs

        define_cfgs :database_name, default_env: "MYSQL_DATABASE", configuration_name: :database_name
        define_cfgs :username, default_env: "MYSQL_USER", configuration_name: :mysql_user, default_value: 'root'
        define_cfgs :password, default_env: "MYSQL_PASSWORD", configuration_name: :mysql_password, default_value: 'root'

      end


    end
  end
end