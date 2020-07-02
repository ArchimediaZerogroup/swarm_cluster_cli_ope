module SwarmClusterCliOpe
  module SyncConfigs
    class Base < Thor::Shell::Basic

      #@return [String]
      attr_accessor :service

      # @param [Hash] configs
      # @param [Continuation] stack_cfgs
      def initialize(stack_cfgs, configs)
        super()
        @configs = configs

        @service = configs[:service]
        @stack_cfgs = stack_cfgs
      end
    end
  end
end