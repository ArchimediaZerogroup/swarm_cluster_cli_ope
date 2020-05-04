# SwarmClusterCliOpe

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/swarm_cluster_cli_ope`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

```swarm_cluster_cli_ope install``` che si occuperà di configurare le varie impostazioni dell'ambiente

FILE di configurazione base:
```json
{"version":"0.1.0","dev_mode":1,"log_level": "3","connections_maps":{"swm1": "swarm_node_1","swm2": "swarm_node_2","swm3": "swarm_node_3"}}
```

### LogLevel:
0 ERROR
1 WARN
2 INFO
3 DEBUG


### Configuratione di un progetto
Si occupa di generare nel progetto il file di configurazione in cui impostare impostazioni specifiche di progetto
quali stack_name
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
swarm_cli_ope services --stack-name=NOME_STACK PATH_FILE_LOCALE NOME_SERVIZIO:DESTINAZIONE_NEL_CONTAINER
```
ES:
```shell script
swarm_cli_ope services --stack-name=webapps-examinerapp-staging ./test_folder/test_1/cartella_bindata/test jeapp:/tmp/.
```

### Rsync da container a locale

```shell script
swarm_cli_ope rsync_binded_from --stack-name=STACK_NAME --service_name NOME_SERVIZIO_SENZA_STACK --binded-container-folders CARTELLA_CONTAINER --destination CARTELLA_DESTINAZIONE
```

ES:
```shell script
swarm_cli_ope rsync_binded_from --stack-name=web-site-ranchilbosco-production --service_name wordpress --binded-container-folders /var/www/html/wp-content/uploads --destination ./uploads
```


## Development

nel file di configurazione creato nella home aggiungere la chiave "dev_mode":1 per collegarsi localmente

### Abbiamo due tasks swarm di simulazione
```shell script
docker stack deploy -c test_folder/test_1/docker_compose.yml test1
docker stack deploy -c test_folder/test_2/docker_compose.yml test2
```

TODO: completare correttamente

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/swarm_cluster_cli_ope.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
 