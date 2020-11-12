module SwarmClusterCliOpe
  module Kubernetes
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
            say "Container non trovato"
            exit
          end


          if yes? "Attenzione, i dati locali o remoti verranno sovrascritti/cancellati?[y,yes]"

            podname = container.name

            if namespace.nil?
              say "Mancata configurazione del namespace tramite argomento o .swarm_cluster_project"
              exit
            end

            cmd = container.exec(['bash -c "apt update && apt install -yq rsync psmisc"'])
            if cmd.execute.failed?
              puts "Problemi nell'installazione di rsync nel pod"
            else
              cmd = container.cp_in(File.expand_path("../../rsync_cfgs/rsyncd.conf", __FILE__), "/tmp/.")
              copy_1 = cmd.execute.failed?
              cmd = container.cp_in(File.expand_path("../../rsync_cfgs/rsyncd.secrets", __FILE__), "/tmp/.")
              copy_2 = cmd.execute.failed?
              cmd = container.exec(['bash -c "chmod 600 /tmp/rsyncd.secrets  && chown root /tmp/*"'])
              chmod = cmd.execute.failed?
              if copy_1 or copy_2 or chmod
                puts "problema nella copia dei file di configurazione nel pod"
              else


                cmd = container.exec('bash -c "rsync --daemon --config=/tmp/rsyncd.conf  --verbose --log-file=/tmp/rsync.log"')
                if cmd.execute.failed?
                  say "Rsync non Inizializzato"
                else
                  local_port = rand(30000..40000)

                  p = IO.popen(container.base_cmd("port-forward #{podname} #{local_port}:873").string_command)
                  pid = p.pid
                  say "PID in execuzione port forward:#{pid}"

                  sleep 1

                  # lanciamo il comando quindi per far rsync
                  rsync_command = [
                    "rsync -az --no-o --no-g",
                    "--delete",
                    "--password-file=#{ File.expand_path("../../rsync_cfgs/password", __FILE__)}"
                  ]

                  if direction == :up
                    rsync_command << "#{local_folder}/."
                    rsync_command << "rsync://root@0.0.0.0:#{local_port}/archives#{remote_folder}"
                  else
                    rsync_command << "rsync://root@0.0.0.0:#{local_port}/archives#{remote_folder}/."
                    rsync_command << local_folder
                  end
                  say "Eseguo rsync #{rsync_command.join(" ")}"


                  cmd = ShellCommandExecution.new(rsync_command)
                  cmd.execute

                  sleep 1
                  Process.kill("INT", pid)


                  say "Eseguo pulizia"
                  cmd = container.exec('bash -c "killall rsync"')
                  cmd.execute
                  cmd = container.exec('bash -c "rm -fr /tmp/rsyncd*"')
                  cmd.execute

                end

              end

            end

          end

        end

      end
    end
  end
end
