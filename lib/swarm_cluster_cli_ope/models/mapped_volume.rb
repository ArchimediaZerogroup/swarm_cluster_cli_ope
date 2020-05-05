module SwarmClusterCliOpe
  module Models
    class MappedVolume < Base

      #@return [Container]
      attr_accessor :container

      #@return [String] tipologia di volume mappato [bind,volume]
      attr_accessor :type

      #@return [String] sorgente del bind
      attr_accessor :source

      #@return [String] destinazione del bind nel container
      attr_accessor :destination

      def initialize(obj, container: nil)
        super(obj)
        @container = container
      end

      ##
      # Controllo se il volume è bindato con l'host
      def is_binded?
        type == 'bind'
      end

      ##
      # Costruisce tutta la path da utilizzare per connettersi via ssh,
      # se siamo in locale non sarà presente la parte di server e ":"
      def ssh_connection_path
        #costruisco la stringa per la parte di connetività del container
        out = "#{source}"
        if container.node.is_over_ssh_uri?
          out = "#{container.node.hostname}:#{out}"
        end
        out

      end

    end
  end
end