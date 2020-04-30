require 'active_support/core_ext/string'
module SwarmClusterCliOpe
  module Models
    class Base
      include LoggerConcern
      include ConfigurationConcern

      def initialize(obj)
        logger.debug { obj.inspect }
        obj.each do |k, v|
          name = k.underscore
          self.send("#{name}=", v) if respond_to?(name.to_sym)
        end
      end

      IDNotFoundOnObject = Class.new(Error)

      ##
      # Esegue un inspect del tipo di componente di docker
      def docker_inspect
        raise IDNotFoundOnObject if id.blank?
        Commands.const_get(self.class.name.demodulize).new.docker_inspect(id).result.first
      end

    end
  end
end