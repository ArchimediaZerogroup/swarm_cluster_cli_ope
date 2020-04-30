module SwarmClusterCliOpe
  module ConfigurationConcern

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      ##
      # Configurazioni standard
      # @return [SwarmClusterCliOpe::Configuration]
      def cfgs
        Configuration.instance
      end
    end


    # @return [SwarmClusterCliOpe::Configuration]
    def cfgs
      self.class.cfgs
    end

  end
end