module SwarmClusterCliOpe
  module SyncConfigs
    ##
    # Classe per la gestione dell'ambiente differente fra local e remote
    # sono presenti le variabili di classe per definire una minima DSL per poter definire le variabili
    # disponibili e i default da utilizzare
    class EnvConfigs
      # @param [Hash] configs
      # @param [SwarmClusterCliOpe::SyncConfigs::Base] sync_configs
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
      def service_name
        @configs[:service] || @sync_configs.service
      end


      def self.define_cfgs(name, default: nil, configuration_name: nil)
        configuration_name ||= name

        define_method(name) do
          return self.instance_variable_get("@#{name}") if self.instance_variable_defined?("@#{name}")
          env_var = @configs[configuration_name.to_sym] || default
          self.instance_variable_set("@#{name}", find_env_file_variable(env_var))
        end

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
  end
end
