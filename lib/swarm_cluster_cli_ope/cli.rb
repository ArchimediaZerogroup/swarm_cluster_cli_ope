require 'thor'
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
        lista = []
        loop do
          connection_name = ask("Aggiungi un server alla lista dei server Manager(inserire uri: ssh://server | unix:///socket/path:")
          result = Node.info(connection_name)
          node = Node.new(name: result.Name, connection_uri: connection_name)
          say "Aggiungo #{node.name} che si connette con DOCKER_HOST=#{node.connection_uri}"
          lista << node
          break if no? "Vuoi inserire al server?[n,no]"
        end
        #scriviamo le varie configurazioni
        cfg = cfgs
        cfg.nodes = lista
        cfg.save_base_cfgs
      end

    end

    desc "config", "Visualizza le configurazioni mergiate (HOME + Project)"
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

    desc "rsync_binded_from", "esegue un rsync dalla cartella bindata (viene sincronizzato il contenuto)"
    option :stack_name, required: false, type: :string, default: cfgs.stack_name
    option :service_name, required: true, type: :string
    option :binded_container_folders, required: true, type: :string, desc: "path della cartella bindata all'interno del container da sincronizzare"
    option :destination, required: false, type: :string, desc: "path della cartella dove sincronizzare il comando"

    def rsync_binded_from
      puts options.inspect

      if yes? "Attenzione, i dati locali verranno sovrascritti/cancellati?[y,yes]"

        # trovo il container del servizio
        container = Models::Container.find_by_service_name(options[:service_name], stack_name: options[:stack_name])

        if container.nil?
          say "Container non trovato con #{options[:stack_name]}@##{options[:service_name]}"
          exit 0
        end

        # creo la cartella in locale se non esiste
        FileUtils.mkdir_p(options[:destination])

        # trovo la cartella bindata e la relativa cartella sul nodo
        volume = container.mapped_volumes.find { |v| v.destination == options[:binded_container_folders] and v.is_binded? }
        if volume.nil?
          say "Non ho trovato il volume bindato con questa destinazione all'interno del container #{options[:binded_container_folders]}"
          exit 0
        end

        #costruisco il comando rsync fra cartella del nodo e cartella sul pc
        cmd = ShellCommandExecution.new(["rsync", "-zar", "--delete", volume.ssh_connection_path, options[:destination]])

        say "Comando da eseguire:"
        say "  #{cmd.string_command}"
        if yes?("Confermare il comando?[y,yes]")
          cmd.execute
        end

      end
    end

    # desc "rsync_binded_to", "esegue un rsync verso la cartella bindata (viene sincronizzato il contenuto)"

  end
end
