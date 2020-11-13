module SwarmClusterCliOpe
  module Kubernetes
    class Configuration < BaseConfiguration

      def shell
        @_shell = Thor::Shell::Basic.new
      end

      delegate :yes?,to: :shell

      ##
      # In kubernetes abbiamo il context, il context può essere ricevuto o dalla configurazione oppure dal current_context
      # di kubelet
      # @return [String]
      def context

        context = merged_configurations.dig(:connections_maps,:context) || nil

        if context.nil?
          cmd = ShellCommandExecution.new(['kubectl config current-context'])
          context = cmd.execute.raw_result[:stdout]
          unless yes? "Attenzione, non era presente il contesto nelle configurazioni, usiamo quello attualmente in uso: #{context}, proseguiamo lo stesso?[y,yes]"
            exit
          end

        end
        context
      end

      ##
      # Salva le configurazioni base in HOME
      def save_base_cfgs
        super do |obj|
          obj.merge({connections_maps: {context: context}})
        end
      end

      ##
      # In k8s utilizziamo namespace come identificativo per avere le idee più chiare a cosi ci riferiamo
      alias_method :namespace, :stack_name


      ##
      # Funzione per la restituzione della classe di sincro corretta
      def get_syncro(name)
        case name
        when 'sqlite3'
          SyncConfigs::Sqlite3
        when 'rsync'
          SyncConfigs::Rsync
        # when 'mysql'
        #   SyncConfigs::Mysql
        # when 'pg'
        #   SyncConfigs::PostGres
        else
          logger.error { "CONFIGURAIONE NON PREVISTA: #{name}" }
          nil
        end
      end

      private

      def evaluate_correct_command_usage(configuration)

        unless configuration[:connections_maps].keys.include?(:context)
          puts "ATTENZIONE, I COMANDI NON DEVONO ESSERE LANCIATI DAL SUB COMANDO K8S"
          exit
        end

      end


    end
  end
end