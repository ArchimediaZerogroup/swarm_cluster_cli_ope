module SwarmClusterCliOpe
  module SyncConfigs
    class Copy < Base

      # @return [String]
      def local_folder
        @configs[:configs][:local]
      end

      # @return [String]
      def remote_folder
        @configs[:configs][:remote]
      end

      # @return [TrueClass, FalseClass]
      def push
        say "#{local_folder} -->> #{remote_folder}" if container.copy_in(local_folder,remote_folder)
      end

      # @return [TrueClass, FalseClass]
      def pull
        say "#{remote_folder} -->> #{local_folder}" if container.copy_out(remote_folder,local_folder)
      end


      private
      # @return [SwarmClusterCliOpe::Models::Container]
      def container
        Models::Container.find_by_service_name(service, stack_name: stack_name)
      end


    end
  end
end