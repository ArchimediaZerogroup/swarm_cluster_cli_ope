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
          lista << Manager.new(ask("Aggiungi un server alla lista dei server Manager:"))
          break if no? "Vuoi inserire al server?[n,no]"
        end
        #scriviamo le varie configurazioni
        cfg = Configuration.instance
        cfg.managers=lista
        cfg.save_base_cfgs
      end

    end

    # DOCKER_HOST=ssh://swarm_node_1 docker stack ls --format="{{json .}}"
    desc "stacks", "Lista degli stacks nel cluster"

    def stacks
      Stack.all.each do |s|
        puts s.name
      end
    end


  end
end