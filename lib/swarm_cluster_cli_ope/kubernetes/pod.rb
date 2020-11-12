module SwarmClusterCliOpe
  module Kubernetes
    ##
    # Interfaccia per la comunicazione con il POD
    class Pod
      include LoggerConcern


      #@return [Hash]
      attr_accessor :pod_description

      #@return [String]
      attr_accessor :context

      # @param [Hash] pod_description -> hash con le configurazioni ritornate da kubectl
      # @param [String] context -> se non presente utiliziamo l'attuale
      def initialize(pod_description, context:)
        @pod_description = pod_description.deep_symbolize_keys
        @context = context
      end


      # @return [String]
      def name
        @pod_description[:metadata][:name]
      end

      def namespace
        @pod_description[:metadata][:namespace]
      end

      # @param [String,Array<String>] cmd -> comando da passare a kubectl exec -- CMD
      # @return [SwarmClusterCliOpe::ShellCommandExecution]
      def exec(cmd)
        base_cmd(["exec", name, "--", cmd].flatten)
      end

      ##
      # Appende solamente la parte base dei comandi
      # @return [SwarmClusterCliOpe::ShellCommandExecution]
      # @param [String,Array<String>] cmd
      def base_cmd(cmd)
        ShellCommandExecution.new([base_kubectl_cmd_env, cmd].flatten)
      end


      ##
      # Comando per la copia del file
      # @param [String] src
      # @param [String] dst
      # @return [SwarmClusterCliOpe::ShellCommandExecution]
      def cp_in(src, dst)
        base_cmd(["cp", src, "#{name}:#{dst}"])
      end


      # @param [String] selector
      # @return [Pod]
      # @param [nil,String] namespace ->  se la sciato vuoto utiliziamo il namespace corrente
      # @param [String, nil] context -> contesto di kubectl, nel caso utilizziamo il corrente
      def self.find_by_selector(selector, namespace: nil, context: nil)

        base_cmd = ["kubectl"]
        base_cmd << "--namespace=#{namespace}" unless namespace.blank?
        base_cmd << "--context=#{context}" unless context.blank?
        base_cmd << "get pod"
        base_cmd << "--selector=#{selector}"
        base_cmd << "--output=json"

        cmd = ShellCommandExecution.new(base_cmd)
        ris = cmd.execute
        if ris.failed?
          puts "Problemi nella ricerca del pod"
          exit
        else
          if ris.result[:items].empty?
            logger.warn { "bbiamo trovato il pod" }
          else
            self.new(ris.result[:items].first, context: context)
          end
        end
      end


      private

      ##
      # Array con i comandi base di kubectl
      # @return [Array<String>]
      def base_kubectl_cmd_env(json: false)
        base_cmd = ["kubectl"]
        base_cmd << "--namespace=#{namespace}" unless namespace.blank?
        base_cmd << "--context=#{context}" unless context.blank?
        base_cmd << "--output=json" if json
        base_cmd
      end


    end
  end
end