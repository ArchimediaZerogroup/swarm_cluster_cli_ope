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
          connection_name = ask("Aggiungi un server alla lista dei server Manager:")
          result = Node.info(connection_name)
          lista << Node.new(name: result.Name, connection_uri: connection_name)
          break if no? "Vuoi inserire al server?[n,no]"
        end
        #scriviamo le varie configurazioni
        cfg = cfgs
        cfg.nodes = lista
        cfg.save_base_cfgs
      end

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
      cfgs.stack_name=stack_name
      cfgs.save_project_cfgs
    end

  end
end
