require 'active_support/concern'

module SwarmClusterCliOpe
  module StackSyncConcern
    extend ActiveSupport::Concern

    included do

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


    end

    #  module ClassMethods

    #  end
  end
end
