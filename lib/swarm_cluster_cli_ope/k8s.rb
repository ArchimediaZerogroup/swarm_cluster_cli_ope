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
    long_desc "Viene utilizzato rsync standard. La root del pod diviene il context di rsync, quindi
                possiamo fare rsync con qualsiasi path del filesystem del pod.
                Il modo con cui scrivere la path sorgente e quello di destinazione è tale a quello di rsync, quindi:
                - voglio copiare il contenuto della cartella /ciao con il contenuto onlin del pod nella cartella
                  /home/pippo, dovrò scrivere   /ciao/. podname:/home/pippo "
    option :stack_name, required: false, type: :string, aliases: ["--namespace", "-n"]

    def rsync(src, dst)
      reg_exp = /(?<pod_name>.*)\:(?<path>.*)/
      if File.exist?(src)
        # il src é la cartella, quindi la destizione è il pod
        direction = :up
        local_path = src
        podname = dst.match(reg_exp)[:pod_name]
        podpath = dst.match(reg_exp)[:path]
      else
        direction = :down
        podname = src.match(reg_exp)[:pod_name]
        podpath = src.match(reg_exp)[:path]
        local_path = dst
      end

      puts "#{src} #{direction} #{dst}"

      cfgs.env(options[:environment]) do |cfgs|

        cfgs.stack_name = options[:stack_name] || cfgs.stack_name

        sync = Kubernetes::SyncConfigs::Rsync.new(cfgs, {
          service: Kubernetes::Pod.find_by_name(podname),
          how: 'rsync',
          configs: {
            local: local_path,
            remote: podpath
          }
        })

        if direction == :down
          sync.pull
        end
        if direction == :up
          sync.push
        end

      


      end
    end


  end
end