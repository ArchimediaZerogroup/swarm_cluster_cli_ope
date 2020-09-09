module SwarmClusterCliOpe
  module SyncConfigs
    class Base < Thor::Shell::Basic
      include LoggerConcern
      #@return [String] nome del servizio dello stack
      attr_accessor :service

      #@return [Hash] configurazioni di sincro
      attr_accessor :configs

      # @param [Hash] configs
      # @param [Continuation] stack_cfgs
      def initialize(stack_cfgs, configs)
        super()
        @configs = configs

        @service = configs[:service]
        @stack_cfgs = stack_cfgs
      end


      delegate :stack_name, to: :@stack_cfgs

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

      private
      # @return [SwarmClusterCliOpe::Models::Container]
      def container
        Models::Container.find_by_service_name(service, stack_name: stack_name)
      end

    end
  end
end