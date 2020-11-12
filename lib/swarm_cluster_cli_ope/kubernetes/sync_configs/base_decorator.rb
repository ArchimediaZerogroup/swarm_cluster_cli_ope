require 'active_support/concern'
module SwarmClusterCliOpe
  module Kubernetes
    module SyncConfigs
      module BaseDecorator
        extend ActiveSupport::Concern

        included do

          delegate :namespace, :context, to: :@stack_cfgs

          private

          # @return [SwarmClusterCliOpe::Kubernetes::Pod]
          def container
            return @service if @service.is_a? SwarmClusterCliOpe::Kubernetes::Pod
            @_container ||= Pod.find_by_selector(service, namespace: namespace, context: context)
          end

        end

        #  module ClassMethods

        #  end
      end
    end
  end
end