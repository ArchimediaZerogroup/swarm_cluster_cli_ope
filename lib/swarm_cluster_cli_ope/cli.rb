require 'thor'
require 'mkmf'
module SwarmClusterCliOpe

  class Cli < Thor
    include LoggerConcern
    include ConfigurationConcern
    include Thor::Actions

    def self.exit_on_failure?
      true
    end

    desc "install", "Creazione della configurazione base della gemma"

    def install
      #contolliamo se presente la configurazione base nella home
      if Configuration.exist_base?
        say "Configurazione già presente"
      else
        #se non presente allora chiediamo le varie configurazioni
        say "Ricordarsi di poter raggiungere i server che verranno inseriti"
        lista = []
        loop do
          connection_name = ask("Aggiungi un server alla lista dei server Manager(inserire uri: ssh://server | unix:///socket/path:")
          result = Node.info(connection_name)
          node = Node.new(name: result.Name, connection_uri: connection_name)
          say "Aggiungo #{node.name} che si connette con DOCKER_HOST=#{node.connection_uri}"
          lista << node
          break if no? "Vuoi inserire altri server?[n,no]"
        end
        #scriviamo le varie configurazioni
        cfg = cfgs
        cfg.nodes = lista
        cfg.save_base_cfgs
      end

    end

    desc "config", "Visualizza le configurazioni mergiate (HOME + Project configuration[#{Configuration.cfgs_project_file_name}])"

    def config
      puts JSON.pretty_generate(cfgs.class.merged_configurations)
    end


    # DOCKER_HOST=ssh://swarm_node_1 docker stack ls --format="{{json .}}"
    desc "stacks", "Lista degli stacks nel cluster"

    def stacks
      Models::Stack.all.each do |s|
        puts s.name
      end
    end

    desc "services", "lista dei servizi per uno stack"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name

    def services
      Models::Service.all(stack_name: options[:stack_name]).each do |s|
        puts s.name
      end
    end

    desc "mc SERVICE_NAME", "Apre MC tra la cartella attuale e il container (potrebbe dar luogo a degli errori, ma funziona)"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name

    def mc(service_name)

      # Disabilito output della libreria
      MakeMakefile::Logging.instance_variable_set(:@logfile, File::NULL)
      unless find_executable 'mc'
        puts "Non hai installato MC"
        exit 0
      end

      begin
        container = Models::Container.find_by_service_name(service_name, stack_name: options[:stack_name])

        server = container.node.hostname

        # Creo container ssh
        #     DOCKER_HOST=ssh://swarm_node_1 docker run --rm -d -p 12222:22 \
        # --volumes-from sistemi-test_swarm_cluster_cli_wordpress.1.zbbz1xxh4vzzccndvs973jnuc \
        # sickp/alpine-sshd:7.5
        #
        cmd = container.docker_command
        cmd.base_suffix_command = ''
        shell_operation = cmd.command do |c|
          c.add("run --rm -d -p 42222:22 --volumes-from #{container.id} sickp/alpine-sshd:7.5")
        end

        puts "Creazione container #{shell_operation.string_command}"
        id_container = shell_operation.execute.raw_result[:stdout]
        puts "Container generato con id:#{id_container}"

        # eseguo tunnel verso nodo e container ssh
        socket_ssh_path = "/tmp/socket_ssh_#{id_container}"
        # ssh -f -N -T -M -S <path-to-socket> -L 13333:0.0.0.0:42222 <server>
        cmd_tunnel = ["ssh", "-f -N -T -M", "-S #{socket_ssh_path}", "-L 13333:0.0.0.0:42222", server].join(" ")
        puts "Apro tunnel"
        puts cmd_tunnel
        system(cmd_tunnel)

        # apro MC
        #     mc . sftp://root:root@0.0.0.0:13333
        mc_cmd = "mc . sftp://root:root@0.0.0.0:13333"
        puts "Apro MC"
        puts mc_cmd
        system(mc_cmd)
      ensure
        if socket_ssh_path
          # chiudo tunnel
          # ssh -S <path-to-socket> -O exit <server>
          close_tunnel_cmd = "ssh -S #{socket_ssh_path} -O exit #{server}"
          puts "Chiudo tunnel"
          # say close_tunnel_cmd
          ShellCommandExecution.new(close_tunnel_cmd).execute
        end

        if id_container
          # cancello container
          # docker stop  #{id_container}
          puts "Spengo container di appoggio"
          puts "docker stop  #{id_container}"
          cmd = container.docker_command
          cmd.base_suffix_command = ''
          stop_ssh_container = cmd.command do |c|
            c.add("stop #{id_container}")
          end
          stop_ssh_container.execute
        end

      end
    end

    desc "cp SRC DEST", "Copia la sorgente in destinazione"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name
    long_desc <<-LONGDESC
      SRC e DEST possono essere un servizio, solo uno di essi può essere un servizio (TODO)
      Per identificare che sia un servizio controllo se nella stringa è presete il :
      il quale mi identifica l'inizio della PATH assoluta all'interno del  primo container del servizio
      dove copiare i files
    LONGDESC

    def cp(src, dest)
      #identifico quale dei due è il servizio e quale la path
      if src.match(/^(.*)\:/)
        container = Models::Container.find_by_service_name(Regexp.last_match[1], stack_name: options[:stack_name])
        ris = container.copy_out(src.match(/\:(.*)$/)[1], dest)
      else
        container = Models::Container.find_by_service_name(dest.match(/^(.*)\:/)[1], stack_name: options[:stack_name])
        ris = container.copy_in(src, dest.match(/\:(.*)$/)[1])
      end
      puts "COMPLETATO" if ris
    end


    desc "configure_project STACK_NAME", "Genera il file di configurazione del progetto contenente il nome dello stack"

    def configure_project(stack_name)
      cfgs.stack_name = stack_name
      cfgs.save_project_cfgs
    end

    desc "service_shell SERVICE_NAME", "apre una shell [default bash] dentro al container"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name
    option :shell, required: false, type: :string, default: 'bash'

    def service_shell(service_name)
      container = Models::Container.find_by_service_name(service_name, stack_name: options[:stack_name])

      cmd = container.docker_command
      cmd.base_suffix_command = ''
      shell_operation = cmd.command do |c|
        c.add("exec -it #{container.id} #{options[:shell]}")
      end

      say "Stai entrando della shell in #{options[:shell]} del container #{options[:stack_name]}->#{container.name}[#{container.id}]"
      system(shell_operation.string_command)
      say "Shell chiusa"
    end


    desc "rsync_binded_from", "esegue un rsync dalla cartella bindata (viene sincronizzato il contenuto)"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name
    option :service_name, required: true, type: :string
    option :binded_container_folders, required: true, type: :string, desc: "path della cartella bindata all'interno del container da sincronizzare"
    option :local_folder, required: false, type: :string, desc: "path della cartella dove sincronizzare il comando"

    def rsync_binded_from
      if yes? "Attenzione, i dati locali verranno sovrascritti/cancellati?[y,yes]"
        rsync_binded(direction: :down, options: options)
      end
    end

    desc "rsync_binded_to", "esegue un rsync verso la cartella bindata"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name
    option :service_name, required: true, type: :string
    option :binded_container_folders, required: true, type: :string, desc: "path della cartella bindata all'interno del container da sincronizzare"
    option :local_folder, required: false, type: :string, desc: "path della cartella dove sincronizzare il comando"

    def rsync_binded_to
      if yes? "ATTENZIONE, i dati remoti verranno sovrascritti/cancellati da quelli locali?[y,yes]"
        rsync_binded(direction: :up, options: options)
      end
    end


    private

    def rsync_binded(direction: :down, options: {})

      # trovo il container del servizio
      container = Models::Container.find_by_service_name(options[:service_name], stack_name: options[:stack_name])

      if container.nil?
        say "Container non trovato con #{options[:stack_name]}@##{options[:service_name]}"
        exit 0
      end


      # trovo la cartella bindata e la relativa cartella sul nodo
      volume = container.mapped_volumes.find { |v| v.destination == options[:binded_container_folders] and v.is_binded? }
      if volume.nil?
        say "Non ho trovato il volume bindato con questa destinazione all'interno del container #{options[:binded_container_folders]}"
        exit 0
      end

      #costruisco il comando rsync fra cartella del nodo e cartella sul pc
      cmd = ["rsync", "-zr", "--delete"]
      if direction == :down
        cmd << "#{volume.ssh_connection_path}/."
        # creo la cartella in locale se non esiste
        FileUtils.mkdir_p(options[:local_folder])
        cmd << options[:local_folder]
      end
      if direction == :up
        cmd << "#{options[:local_folder]}/."
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
