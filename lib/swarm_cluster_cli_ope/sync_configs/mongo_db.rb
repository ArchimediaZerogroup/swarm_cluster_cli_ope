module SwarmClusterCliOpe
  module SyncConfigs
    class MongoDb < BaseDatabase

      # @return [TrueClass, FalseClass]
      def pull
        resume('pull')
        if yes?("Confermare il comando?[y,yes]")

          tmp_file = make_dump(remote, container)

          local_container.copy_in(tmp_file, tmp_file)

          restore(tmp_file, remote, local, local_container)
        end
        true
      end

      # @return [TrueClass, FalseClass]
      def push
        resume('PUSH')
        if yes?("ATTENZIONE !!!!!!PUSH!!!!! - Confermare il comando?[y,yes]")
          tmp_file = make_dump(local, local_container)
          container.copy_in(tmp_file, tmp_file)
          restore(tmp_file, local, remote, container)
        end
        true
      end

      ##
      # Classe interna che rappresenta le configurazioni del DB
      class EnvConfigs < BaseDatabase::EnvConfigs

        define_cfgs :database_name, configuration_name: :database_name
        define_cfgs :username, configuration_name: :username
        define_cfgs :password, configuration_name: :password

        define_cfgs :database_version, default_env: "MONGO_VERSION", configuration_name: :version

        ##
        # Possiamo definire una lista, comma-separated, per limitare le collections da non importare
        define_cfgs :exclude_from_sync, default_env: "EXCLUDE_FROM_SYNC", configuration_name: :exclude_from_sync, default_value: ""

        ##
        # Helper per avere un array di collections da non sincronizzare, specifico per mongodb
        # @return [Array<String>]
        def excluded_collections
          return [] if exclude_from_sync.nil?
          exclude_from_sync.split(",").compact
        end

      end

      private

      # @param [String] tmp_file
      # @param [EnvConfigs] from_env environment sorgente (per rinominare anche il nome del DB)
      # @param [EnvConfigs] to_env environment di arrivo (per rinominare anche il nome del DB)
      # @param [SwarmClusterCliOpe::Models::Container] cnt in cui eseguire l'import
      def restore(tmp_file, from_env, to_env, cnt)
        command = []
        command << "bash -c '"
        command << "mongorestore"
        command << "--nsFrom  '#{from_env.database_name}.*'"
        command << "--nsTo '#{to_env.database_name}.*'"
        command << "--drop --archive=#{tmp_file} --gzip"
        command << "'"

        cnt.exec(command.join " ")
      end

      # @param [EnvConfigs] environment
      # @param [SwarmClusterCliOpe::Models::Container] cnt
      def make_dump(environment, cnt)
        tmp_file = "/tmp/dump.#{Time.now.to_i}.archive"
        command = []
        command << "bash -c '"

        command << "mongodump --db #{environment.database_name} "
        environment.excluded_collections.each do |collection|
          command << " --excludeCollection \"#{collection}\" "
        end
        command << "--username \"#{environment.username}\" " if environment.username
        command << "--password \"#{environment.password}\" " if environment.password
        command << "--archive --gzip"

        command << "' > #{tmp_file}"
        cnt.exec(command.join " ")
        tmp_file
      end

    end
  end
end