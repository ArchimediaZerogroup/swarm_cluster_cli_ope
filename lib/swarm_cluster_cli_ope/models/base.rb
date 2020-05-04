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
          self.send("#{name}=", v) if respond_to?("#{name}=".to_sym)
        end
      end

      IDNotFoundOnObject = Class.new(Error)

      ##
      # Esegue un inspect del tipo di componente di docker
      def docker_inspect
        raise IDNotFoundOnObject if id.blank?
        Commands.const_get(self.class.name.demodulize).new(connection_uri: mapped_uri_connection).docker_inspect(id).result.first
      end

      ##
      # Override della connessione al nodo corretto, i container sono legati allo swarm, conseguentemente dobbiamo
      # collegarci al nodo giusto, di default lasiamo nil, così che prende le cfgs di default
      def mapped_uri_connection
        nil
      end

    end
  end
end