# SwarmClusterCliOpe
WIP to translate
Gemma per la gestione semplificata degli operatori con un cluster swarm

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swarm_cluster_cli_ope'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install swarm_cluster_cli_ope

## Usage

Una volta installato lanciare il comando 

```swarm_cli_ope install``` che si occuperà di configurare le varie impostazioni dell'ambiente

FILE di configurazione base:
```json
{"version":"0.1.0","dev_mode":1,"log_level": "3","connections_maps":{"swm1": "swarm_node_1","swm2": "swarm_node_2","swm3": "swarm_node_3"}}
```

### LogLevel:
0 ERROR
1 WARN
2 INFO
3 DEBUG


### ENV differenti
Tutti i comandi possono essere accompagnati con -e, per scopparli nel relativo ENVIRONMENT

### Configuratione di un progetto
Si occupa di generare nel progetto il file di configurazione in cui impostare impostazioni specifiche di progetto
quali stack_name (.swarm_cluster_project)
```shell script
swarm_cli_ope configure_project STACK_NAME
```

### Configurazioni applicate nel progetto:
```shell script
swarm_cli_ope config
```

### Elenco di tutti gli stack disponibili:
```shell script
swarm_cli_ope stacks
```


### MC:
Apre MC collegato al container del servizio specificato
```shell script
swarm_cli_ope mc SERVICE_NAME --stack-name=NOME_STACK
```

### SHELL:
Apre una shell (default bash) collegato al container del servizio specificato
```shell script
swarm_cli_ope shell SERVICE_NAME --stack-name=NOME_STACK
```

### Elenco di tutti i servizi
Se siamo nel progetto con il file di progetto vedremo comunque i servizi filtrati
```shell script
swarm_cli_ope services
```

filtrando per stack:
  
```shell script
swarm_cli_ope services --stack-name=NOME_STACK
```

### Copia di files da/verso container attraverso il docker cp   
```shell script
swarm_cli_ope cp --stack-name=NOME_STACK PATH_FILE_LOCALE NOME_SERVIZIO:DESTINAZIONE_NEL_CONTAINER
```

### Rsync da/a container a/da locale

Utilizzare `rsync_binded_from` per scaricare e `rsync_binded_to` per caricare


```shell script
swarm_cli_ope rsync_binded_from --stack-name=STACK_NAME --service_name NOME_SERVIZIO_SENZA_STACK --binded-container-folders CARTELLA_CONTAINER --local-folder CARTELLA_DESTINAZIONE
```

## Development

nel file di configurazione creato nella home aggiungere la chiave "dev_mode":1 per collegarsi localmente

### Abbiamo due tasks swarm di simulazione
```shell script
docker stack deploy -c test_folder/test_1/docker-compose.yml test1_stack
docker stack deploy -c test_folder/test_1/docker-compose.yml test1_staging
docker stack deploy -c test_folder/test_2/docker_compose.yml test2
```

Per simulare una sincronizzazione fra locale e remoto di un mysql, lanciamo lo stesso stack anche come compose, in modo
da trovarci sulla stessa macchina con tutte e due le situazioni
```shell script
docker-compose up -f test_folder/test_1/docker-compose.yml -d
```



To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version 
number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git 
commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
 