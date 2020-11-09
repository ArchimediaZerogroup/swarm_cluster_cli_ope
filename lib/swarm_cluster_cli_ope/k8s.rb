module SwarmClusterCliOpe
  class K8s < Thor
    include LoggerConcern
    include ConfigurationConcern
    include Thor::Actions
    include StackSyncConcern

    def self.exit_on_failure?
      true
    end

    def self.cfgs
      SwarmClusterCliOpe::Kubernetes::Configuration.instance
    end

    desc "install", "Creazione della configurazione base della gemma"

    def install
      #contolliamo se presente la configurazione base nella home
      if Configuration.exist_base?
        say "Configurazione già presente"
      else
        #se non presente allora chiediamo le varie configurazioni
        if yes? "Sei nel contesto corretto di kubectl?"
          #scriviamo le varie configurazioni
          cfg = cfgs
          cfg.save_base_cfgs
        else
          say "Cambia prima contesto, sarà quello usato per l'installazione"
        end
      end

    end


    desc "rsync <src> <dst>", "esegue un rsync dalla cartella (viene sincronizzato il contenuto)"

    def rsync(src, dst)
      if yes? "Attenzione, i dati locali o remoti verranno sovrascritti/cancellati?[y,yes]"

        reg_exp = /(?<pod_name>.*)\:(?<path>.*)/
        if File.exist?(src)
          # il src é la cartella, quindi la destizione è il pod
          direction = :upload
          local_path = src
          podname = dst.match(reg_exp)[:pod_name]
          podpath = dst.match(reg_exp)[:path]
        else
          direction = :download
          podname = src.match(reg_exp)[:pod_name]
          podpath = src.match(reg_exp)[:path]
          local_path = dst
        end

        puts "#{src} #{direction} #{dst}"

        cfgs.env(options[:environment]) do |cfgs|
          base_cmd = ["kubectl", "-n #{cfgs.stack_name}"]

          cmd = ShellCommandExecution.new([*base_cmd, "exec #{podname}", "--", 'bash -c "apt update && apt install -yq rsync psmisc"'])
          if cmd.execute.failed?
            puts "Problemi nell'installazione di rsync nel pod"
          else
            cmd = ShellCommandExecution.new([*base_cmd, "cp", File.expand_path("../kubernetes/rsync_cfgs/rsyncd.conf", __FILE__), "#{podname}:/tmp/."])
            copy_1 = cmd.execute.failed?
            cmd = ShellCommandExecution.new([*base_cmd, "cp", File.expand_path("../kubernetes/rsync_cfgs/rsyncd.secrets", __FILE__), "#{podname}:/tmp/."])
            copy_2 = cmd.execute.failed?
            cmd = ShellCommandExecution.new([*base_cmd, "exec #{podname}", "--", 'bash -c "chmod 600 /tmp/rsyncd.secrets  && chown root /tmp/*"'])
            chmod = cmd.execute.failed?
            if copy_1 or copy_2 or chmod
              puts "problema nella copia dei file di configurazione nel pod"
            else


              cmd = ShellCommandExecution.new([*base_cmd, "exec -i #{podname}", "--", 'bash -c "rsync --daemon --config=/tmp/rsyncd.conf  --verbose --log-file=/tmp/rsync.log"'])
              if cmd.execute.failed?
                puts "Rsync non startato"
              else
                local_port = rand(30000..40000)

                p = IO.popen([*base_cmd, "port-forward #{podname} #{local_port}:873"].join(" "))
                pid = p.pid
                puts "PID in execuzione port forward:#{pid}"

                sleep 1

                # lanciamo il comando quindi per far rsync
                rsync_command = [
                  "rsync -az --no-o --no-g",
                  "--delete",
                  "--password-file=#{ File.expand_path("../kubernetes/rsync_cfgs/password", __FILE__)}"
                ]

                if direction == :upload
                  rsync_command << local_path
                  rsync_command << "rsync://root@0.0.0.0:#{local_port}/archives#{podpath}"
                else
                  rsync_command << "rsync://root@0.0.0.0:#{local_port}/archives#{podpath}"
                  rsync_command << local_path
                end


                cmd = ShellCommandExecution.new(rsync_command)
                cmd.execute

                sleep 1
                Process.kill("INT", pid)


                puts "Eseguo pulizia"
                cmd = ShellCommandExecution.new([*base_cmd, "exec -i #{podname}", "--", 'bash -c "killall rsync"'])
                cmd.execute
                cmd = ShellCommandExecution.new([*base_cmd, "exec -i #{podname}", "--", 'bash -c "rm -fr /tmp/rsyncd*"'])
                cmd.execute

              end

            end

          end

        end


      end
    end


  end
end