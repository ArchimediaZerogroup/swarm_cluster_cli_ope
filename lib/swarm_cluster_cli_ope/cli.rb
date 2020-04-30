require 'thor'
module SwarmClusterCliOpe

  class Cli < Thor
    include LoggerConcern
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
          lista << Node.new(name:result.Name, connection_uri: connection_name)
          break if no? "Vuoi inserire al server?[n,no]"
        end
        #scriviamo le varie configurazioni
        cfg = Configuration.instance
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
    option :stack_name, required: false, type: :string, default: Configuration.instance.stack_name

    def services
      Models::Service.all(stack_name: options[:stack_name]).each do |s|
        puts s.name
      end
    end


  end
end