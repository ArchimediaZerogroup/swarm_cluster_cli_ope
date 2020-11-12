module SwarmClusterCliOpe
  module Kubernetes
    module SyncConfigs
      class Base < Thor::Shell::Basic
        include LoggerConcern
        #@return [String] nome del servizio dello stack
        attr_accessor :service

        #@return [Hash] configurazioni di sincro
        attr_accessor :configs

        # @param [Hash] configs
        # @param [Configuration] stack_cfgs
        def initialize(stack_cfgs, configs)
          super()
          @configs = configs

          @service = configs[:service]
          @stack_cfgs = stack_cfgs
        end


        delegate :namespace, :context, to: :@stack_cfgs

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

        # @return [SwarmClusterCliOpe::Kubernetes::Pod]
        def container
          @_container ||= Pod.find_by_selector(service, namespace: namespace, context: context)
        end

      end
    end
  end
end