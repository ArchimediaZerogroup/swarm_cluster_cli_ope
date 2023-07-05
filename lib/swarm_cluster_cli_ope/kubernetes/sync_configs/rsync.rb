require 'fileutils'
require 'tmpdir'

module SwarmClusterCliOpe
  module Kubernetes
    module SyncConfigs
      class Rsync < SwarmClusterCliOpe::SyncConfigs::Base

        include BaseDecorator

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

            # controllo presenza comandi necessari
            command_installed = false
            install_rsync = false
            install_psmisc = false
            if container.exec(['sh -c "command -v apt"'], allow_failure: true).success?
              puts "Container Ubuntu"
              install_rsync = container.exec(['sh -c "command -v rsync || apt update && apt install -yq rsync "'], allow_failure: true).success?
              install_psmisc = container.exec(['sh -c "command -v killall || apt update && apt install -yq psmisc"'], allow_failure: true).success?
            end

            if container.exec(['sh -c "command -v apk"'], allow_failure: true).success?
              puts "Container Alpine"
              install_rsync = container.exec(['sh -c "command -v rsync || apk add rsync"'], allow_failure: true).success?
              install_psmisc = true
            end

            if install_rsync and install_psmisc
              command_installed = true
            else
              puts "Problemi nell'installazione di rsync nel pod"
            end

            if command_installed
              cmd = container.cp_in(configs_path("rsyncd.conf"), "/tmp/.")
              copy_1 = cmd.execute.failed?
              cmd = container.cp_in(configs_path("rsyncd.secrets"), "/tmp/.")
              copy_2 = cmd.execute.failed?
              cmd = container.exec(['bash -c "chmod 600 /tmp/rsyncd.secrets  && chown root /tmp/*"'])
              chmod = cmd.failed?
              if copy_1 or copy_2 or chmod
                puts "problema nella copia dei file di configurazione nel pod"
              else

                begin
                  cmd = container.exec('bash -c "rsync --daemon --config=/tmp/rsyncd.conf  --verbose --log-file=/tmp/rsync.log"')
                  if cmd.failed?
                    say "Rsync non Inizializzato"
                  else
                    begin
                      local_port = rand(30000..40000)

                      p = IO.popen(container.base_cmd("port-forward #{podname} #{local_port}:873").string_command)
                      pid = p.pid
                      say "PID in execuzione port forward:#{pid}"

                      # directory temporanea dove salvare pa pwd
                      pwd_dir = Dir.mktmpdir
                      begin

                        sleep 1

                        # creo il file password temporaneo
                        tmp_file_path = File.join(pwd_dir,"password")
                        FileUtils.copy(configs_path("password"),tmp_file_path)
                        FileUtils.chmod(0600,tmp_file_path)

                        # lanciamo il comando quindi per far rsync
                        rsync_command = [
                          "rsync -az --no-o --no-g",
                          "--delete",
                          "--password-file=#{tmp_file_path}"
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

                      ensure
                        sleep 1
                        say "Stoppo porta forwarded"
                        Process.kill("INT", pid)
                        FileUtils.remove_entry pwd_dir
                      end
                    ensure
                      say "Tolgo il servizio di rsyn"
                      container.exec('bash -c "killall rsync"')
                    end
                  end

                ensure
                  say "Eseguo pulizia configurazioni caricate"
                  container.exec('bash -c "rm -fr /tmp/rsyncd*"')
                end

              end

            end

          end

        end

        ##
        # Estrapola la path al file di configurazione
        # @param [String] file
        # @return [String]
        def configs_path(file)
          File.expand_path("../../rsync_cfgs/#{file}", __FILE__)
        end

      end
    end
  end
end
