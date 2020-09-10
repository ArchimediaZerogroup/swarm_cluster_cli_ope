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


      ##
      # Costruisce i metodi che restituiscono i valori delle configurazioni
      #
      # @param [String,Symbol] name -> nome della stringa con cui viene generato il metodo
      # @param [String,Symbol] default_env -> nome env default nel caso non sia passato
      # @param [String,Symbol] configuration_name -> nome della configurazione da utilizzare per estrapolare la configurazione
      #                                           in automatico viene tenuto conto se cercare per la versione
      #                                           con _env o senza....precedenza SENZA
      # @param [nil,String] default_value se non è estrapolato nessun valore, viene utilizzato il valore di default
      def self.define_cfgs(name, default_env:, configuration_name:,default_value:nil)
        configuration_name ||= name

        define_method(name) do
          return self.instance_variable_get("@#{name}") if self.instance_variable_defined?("@#{name}")

          #valore restituito direttamente dalla configurazione
          if @configs.key?(configuration_name)
            value = @configs["#{configuration_name}".to_sym] || default_value
          else
            env_var = @configs["#{configuration_name}_env".to_sym] || default_env
            value = find_env_file_variable(env_var) || default_value
          end
          self.instance_variable_set("@#{name}", value)
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
