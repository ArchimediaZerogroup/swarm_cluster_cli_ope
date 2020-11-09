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


    end
  end
end