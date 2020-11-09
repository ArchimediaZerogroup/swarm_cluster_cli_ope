require 'active_support/concern'

module SwarmClusterCliOpe
  module ConfigurationConcern
    extend ActiveSupport::Concern

    included do
      # @return [SwarmClusterCliOpe::Configuration]
      def cfgs
        self.class.cfgs
      end
    end

    module ClassMethods
      ##
      # Configurazioni standard
      # @return [SwarmClusterCliOpe::Configuration]
      def cfgs
        Configuration.instance
      end
    end
  end
end