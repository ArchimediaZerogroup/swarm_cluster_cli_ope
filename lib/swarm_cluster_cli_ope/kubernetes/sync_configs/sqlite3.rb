module SwarmClusterCliOpe
  module Kubernetes
    module SyncConfigs
      class Sqlite3 < SwarmClusterCliOpe::SyncConfigs::Sqlite3
        include BaseDecorator
      end
    end
  end
end