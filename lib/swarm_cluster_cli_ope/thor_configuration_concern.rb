require 'active_support/concern'

module SwarmClusterCliOpe
  module ThorConfigurationConcern
    extend ActiveSupport::Concern

    included do

      desc "config", "Visualizza le configurazioni mergiate (HOME + Project configuration[#{Configuration.cfgs_project_file_name}])"

      def config
        cfgs.env(options[:environment]) do
          puts JSON.pretty_generate(cfgs.merged_configurations)
        end
      end

      desc "configure_project STACK_NAME", "Genera il file di configurazione del progetto contenente il nome dello stack"

      def configure_project(stack_name)
        cfgs.env(options[:environment]) do |c|
          c.stack_name = stack_name
          c.save_project_cfgs
        end
      end

    end

  end
end