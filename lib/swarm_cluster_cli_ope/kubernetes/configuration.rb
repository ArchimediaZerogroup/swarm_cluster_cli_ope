module SwarmClusterCliOpe
  module Kubernetes
    class Configuration < BaseConfiguration


      ##
      # In kubernetes abbiamo il context, il context può essere ricevuto o dalla configurazione oppure dal current_context
      # di kubelet
      # @return [String]
      def context
        cmd = ShellCommandExecution.new(['kubectl config current-context'])
        cmd.execute.raw_result[:stdout]
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


    end
  end
end