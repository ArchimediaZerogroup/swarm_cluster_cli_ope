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

    class_option :environment, required: false, type: :string, aliases: [:e],
                 desc: "Esegue tutte le operazioni nell'env scelto, il file di configurazione dovrà avere il nome: #{Configuration.cfgs_project_file_name}.ENV"

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
      cfgs.env(options[:environment]) do
        puts JSON.pretty_generate(cfgs.merged_configurations)
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
    option :stack_name, required: false, type: :string

    def services
      cfgs.env(options[:environment]) do |cfgs|
        stack_name = options[:stack_name] || cfgs.stack_name
        Models::Service.all(stack_name: stack_name).each do |s|
          puts s.name
        end
      end
    end

    desc "mc SERVICE_NAME", "Apre MC tra la cartella attuale e il container (potrebbe dar luogo a degli errori, ma funziona)"
    option :stack_name, required: false, type: :string

    def mc(service_name)
      cfgs.env(options[:environment]) do |cfgs|
        stack_name = options[:stack_name] || cfgs.stack_name
        # Disabilito output della libreria
        MakeMakefile::Logging.instance_variable_set(:@logfile, File::NULL)
        unless find_executable 'mc'
          puts "Non hai installato MC"
          exit 0
        end

        begin
          container = Models::Container.find_by_service_name(service_name, stack_name: stack_name)

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
    end

    desc "cp SRC DEST", "Copia la sorgente in destinazione"
    option :stack_name, required: false, type: :string
    long_desc <<-LONGDESC
      SRC e DEST possono essere un servizio, solo uno di essi può essere un servizio (TODO)
      Per identificare che sia un servizio controllo se nella stringa è presete il :
      il quale mi identifica l'inizio della PATH assoluta all'interno del  primo container del servizio
      dove copiare i files
    LONGDESC

    def cp(src, dest)
      cfgs.env(options[:environment]) do |cfgs|

        cfgs.stack_name = options[:stack_name] || cfgs.stack_name

        #identifico quale dei due è il servizio e quale la path
        if src.match(/^(.*)\:/)
          service_name = Regexp.last_match[1]
          remote = src.match(/\:(.*)$/)[1]
          local = dest
          execute = :pull
        else
          service_name = dest.match(/^(.*)\:/)[1]
          remote = dest.match(/\:(.*)$/)[1]
          local = src
          execute = :push
        end


        cmd = SyncConfigs::Copy.new(cfgs, {
          service: service_name,
          how: 'copy',
          configs: {
            local: local,
            remote: remote
          }
        })

        puts "COMPLETATO" if cmd.send(execute)

      end
    end


    desc "configure_project STACK_NAME", "Genera il file di configurazione del progetto contenente il nome dello stack"

    def configure_project(stack_name)
      cfgs.env(options[:environment]) do |c|
        c.stack_name = stack_name
        c.save_project_cfgs
      end
    end


    desc "service_shell SERVICE_NAME", "apre una shell [default bash] dentro al container"
    option :stack_name, required: false, type: :string
    option :shell, required: false, type: :string, default: 'bash'

    def service_shell(service_name)
      cfgs.env(options[:environment]) do |cfgs|
        stack_name = options[:stack_name] || cfgs.stack_name
        container = Models::Container.find_by_service_name(service_name, stack_name: stack_name)

        cmd = container.docker_command
        cmd.base_suffix_command = ''
        shell_operation = cmd.command do |c|
          c.add("exec -it #{container.id} #{options[:shell]}")
        end

        say "Stai entrando della shell in #{options[:shell]} del container #{stack_name}->#{container.name}[#{container.id}]"
        system(shell_operation.string_command)
        say "Shell chiusa"
      end
    end


    desc "rsync_binded_from", "esegue un rsync dalla cartella bindata (viene sincronizzato il contenuto)"
    option :stack_name, required: false, type: :string
    option :service_name, required: true, type: :string
    option :binded_container_folders, required: true, type: :string, desc: "path della cartella bindata all'interno del container da sincronizzare"
    option :local_folder, required: true, type: :string, desc: "path della cartella dove sincronizzare il comando"

    def rsync_binded_from
      if yes? "Attenzione, i dati locali verranno sovrascritti/cancellati?[y,yes]"
        rsync_binded(direction: :down, options: options)
      end
    end

    desc "rsync_binded_to", "esegue un rsync verso la cartella bindata"
    option :stack_name, required: false, type: :string
    option :service_name, required: true, type: :string
    option :binded_container_folders, required: true, type: :string, desc: "path della cartella bindata all'interno del container da sincronizzare"
    option :local_folder, required: true, type: :string, desc: "path della cartella dove sincronizzare il comando"

    def rsync_binded_to
      if yes? "ATTENZIONE, i dati remoti verranno sovrascritti/cancellati da quelli locali?[y,yes]"
        rsync_binded(direction: :up, options: options)
      end
    end

    desc "version", "versione della cli"
    def version
      say VERSION
    end

    desc "stacksync [DIRECTION:pull|push]", "Si occupa di scaricare|caricare,utilizzando le configurazioni presenti, i dati dallo stack remoto"
    long_desc <<-LONGDESC.gsub("\n", "\x5")
      le configurazioni sono contenute nell'array: sync_configs.
      ogni configurazione è composta da:
      { 
       service:"" 
       how:"" 
       configs:{ }
      }
      - service è il nome del servizio
      - how è il come sincronizzare, definendo la tipologia:
      ---- pg      -> DB TODO
      ---- mysql   -> DB dump con mysql
      ---- sqlite3 -> DB: viene eseguita una copia del file
      ---- rsync   -> RSYNC
      - configs:  è un hash con le configurazioni per ogni tipo di sincronizzazione

      Possibili CFGS per tipologia:
      rsync:
      --local:   -> path cartella locale
      --remote:  -> path cartella remota (contesto del container)

      sqlite3:
      --local:   -> path al file
      --remote:  -> path al file remoto (contesto del container)

      mysql:
      --local:  -> hash di configurazioni per il DB locale
        - service: "db"                         -> nome del servizio nel compose locale, DEFAULT: quello definito sopra 
        - mysql_password_env: "MYSQL_PASSWORD"  -> variabile ambiente interna al servizio contenente PASSWORD, DEFAULT: MYSQL_PASSWORD 
        - mysql_password: "root"                -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: root
        - mysql_user_env: "MYSQL_USER"          -> variabile ambiente interna al servizio contenente USERNAME, DEFAULT: MYSQL_USER 
        - mysql_user: "root"                    -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: root
        - database_name_env: "MYSQL_DATABASE"   -> variabile ambiente interna al servizio contenente NOME DB, DEFAULT: MYSQL_DATABASE         
        - database_name: "nome_db"       -> valore in chiaro, in sostituzione della variabile ambiente         
      --remote: -> hash di configurazioni per il DB remoto
        - service: "db"                         -> nome del servizio nel compose locale, DEFAULT: quello definito sopra 
        - mysql_password_env: "MYSQL_PASSWORD"  -> variabile ambiente interna al servizio contenente PASSWORD, DEFAULT: MYSQL_PASSWORD 
        - mysql_password: "root"                -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: root
        - mysql_user_env: "MYSQL_USER"          -> variabile ambiente interna al servizio contenente USERNAME, DEFAULT: MYSQL_USER 
        - mysql_user: "root"              -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: root
        - database_name_env: "MYSQL_DATABASE"       -> variabile ambiente interna al servizio contenente NOME DB, DEFAULT: MYSQL_DATABASE         
        - database_name: "MYSQL_DATABASE"       -> valore in chiaro, in sostituzione della variabile ambiente     
      pg:
      --local:  -> hash di configurazioni per il DB locale
        - service: "db"                         -> nome del servizio nel compose locale, DEFAULT: quello definito sopra 
        - pg_password_env: "POSTGRES_USER"      -> variabile ambiente interna al servizio contenente PASSWORD, DEFAULT: POSTGRES_PASSWORD 
        - pg_password: ""                       -> valore in chiaro, in sostituzione della variabile ambiente
        - pg_user_env: "POSTGRES_USER"          -> variabile ambiente interna al servizio contenente USERNAME, DEFAULT: POSTGRES_USER 
        - pg_user: "postgres"                   -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: postgres
        - database_name_env: "POSTGRES_DB"      -> variabile ambiente interna al servizio contenente NOME DB, DEFAULT: POSTGRES_DB         
        - database_name: "nome_db"              -> valore in chiaro, in sostituzione della variabile ambiente             
      --remote: -> hash di configurazioni per il DB remoto
        - service: "db"                         -> nome del servizio nel compose locale, DEFAULT: quello definito sopra 
        - pg_password_env: "POSTGRES_USER"      -> variabile ambiente interna al servizio contenente PASSWORD, DEFAULT: POSTGRES_PASSWORD 
        - pg_password: ""                       -> valore in chiaro, in sostituzione della variabile ambiente
        - pg_user_env: "POSTGRES_USER"          -> variabile ambiente interna al servizio contenente USERNAME, DEFAULT: POSTGRES_USER 
        - pg_user: "postgres"                   -> valore in chiaro, in sostituzione della variabile ambiente, DEFAULT: postgres
        - database_name_env: "POSTGRES_DB"      -> variabile ambiente interna al servizio contenente NOME DB, DEFAULT: POSTGRES_DB         
        - database_name: "nome_db"              -> valore in chiaro, in sostituzione della variabile ambiente     
              

      EXAMPLE:
      Esempio di sincronizzazione di un file sqlite3 e una cartella
      {
        "stack_name": "test1",
        "sync_configs": [
          {
            "service": "second",
            "how": "rsync",
            "configs": {
              "remote": "/test_bind",
              "local": "./uploads"
            }
          },
          {
            "service": "test_sqlite3",
            "how": "sqlite3",
            "configs": {
              "remote": "/cartella_sqlite3/esempio.sqlite3",
              "local": "./development.sqlite3"
            }
          }
        ]
      }
    LONGDESC

    def stacksync(direction)
      direction = case direction
                  when 'push'
                    :push
                  when 'pull'
                    :pull
                  else
                    raise "ONLY [push|pull] action accepted"
                  end
      cfgs.env(options[:environment]) do |cfgs|
        sync_cfgs = cfgs.sync_configurations
        if sync_cfgs.empty?
          say "Attenzione, configurazioni di sincronizzazione vuoto. Leggere la documentazione"
        else
          sync_cfgs.each do |sync|
            say "----------->>>>>>"
            say "[ #{sync.class.name} ]"
            sync.send(direction)
            say "COMPLETE"
            say "<<<<<<-----------"
          end
        end
      end
    end

    private

    def rsync_binded(direction: :down, options: {})
      cfgs.env(options[:environment]) do |cfgs|
        cfgs.stack_name = options[:stack_name] || cfgs.stack_name
        sync = SyncConfigs::Rsync.new(cfgs, {
          service: options[:service_name],
          how: 'rsync',
          configs: {
            local: options[:local_folder],
            remote: options[:binded_container_folders]
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
