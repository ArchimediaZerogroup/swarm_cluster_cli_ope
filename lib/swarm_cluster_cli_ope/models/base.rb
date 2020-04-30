require 'active_support/core_ext/string'
module SwarmClusterCliOpe
  module Models
    class Base
      include LoggerConcern

      def initialize(obj)
        logger.debug { obj.inspect }
        obj.each do |k, v|
          name = k.underscore
          self.send("#{name}=", v) if respond_to?(name.to_sym)
        end
      end

    end
  end
end