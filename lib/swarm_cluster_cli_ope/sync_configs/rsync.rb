module SwarmClusterCliOpe
  module SyncConfigs
    class Rsync < Base


      # @return [String]
      def local_folder
        @configs[:configs][:local]
      end

      # @return [String]
      def remote_folder
        @configs[:configs][:remote]
      end


      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def push
        execute(direction: :up)
      end

      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def pull
        execute(direction: :down)
      end


      private
      def execute(direction: :down)

        if container.nil?
          say "Container non trovato con #{stack_name}@##{service}"
          exit 0
        end


        # trovo la cartella bindata e la relativa cartella sul nodo
        volume = container.mapped_volumes.find { |v| v.destination == remote_folder and v.is_binded? }
        if volume.nil?
          say "Non ho trovato il volume bindato con questa destinazione all'interno del container #{remote_folder}"
          exit 0
        end

        #costruisco il comando rsync fra cartella del nodo e cartella sul pc
        cmd = ["rsync", "-zr", "--delete"]
        if direction == :down
          cmd << "#{volume.ssh_connection_path}/."
          # creo la cartella in locale se non esiste
          FileUtils.mkdir_p(local_folder)
          cmd << local_folder
        end
        if direction == :up
          cmd << "#{local_folder}/."
          cmd << volume.ssh_connection_path
        end

        cmd = ShellCommandExecution.new(cmd)

        say "Comando da eseguire:"
        say "  #{cmd.string_command}"
        if yes?("Confermare il comando?[y,yes]")
          cmd.execute
        end


      end


    end
  end
end
