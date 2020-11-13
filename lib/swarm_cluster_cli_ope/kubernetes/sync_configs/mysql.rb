module SwarmClusterCliOpe
  module Kubernetes
    module SyncConfigs
      class Mysql < SwarmClusterCliOpe::SyncConfigs::Mysql

        include BaseDecorator
      end
    end
  end
end