module SwarmClusterCliOpe
  module SyncConfigs
    class Base < Thor::Shell::Basic

      #@return [String] nome del servizio dello stack
      attr_accessor :service

      # @param [Hash] configs
      # @param [Continuation] stack_cfgs
      def initialize(stack_cfgs, configs)
        super()
        @configs = configs

        @service = configs[:service]
        @stack_cfgs = stack_cfgs
      end


      ##
      # Funzione che dobbiamo sovrascrivere per identificare cosa fare quando scarichiamo i dati
      def pull
        raise "TO OVERRIDE"
      end

      ##
      # Funzione che dobbiamo sovrascrivere per identificare cosa fare quando carichiamo i dati
      def push
        raise "TO OVERRIDE"
      end

    end
  end
end