require "singleton"
require "fileutils"
require "json"
require 'digest'
require "active_support/core_ext/hash"
module SwarmClusterCliOpe
  ##
  # Classe per la gestione delle configurazioni, unisce le configurazioni di base alle configurazioni di progetto;
  # le quali sono salvate nel file di configurazione del progetto .swarm_cluster_project sottoforma di json
  # che vengono mergiate sulle configurazioni base
  class Configuration < BaseConfiguration


    ##
    # Lista di nodi su cui lavorare
    # @return [Array<SwarmClusterCliOpe::Manager>]
    def managers
      return @_managers if @_managers
      @_managers = self.nodes.select { |n| read_managers_cache_list.include?(n.name) }.collect { |c| Manager.new(name: c.name.to_s, connection_uri: c.connection_uri) }
    end

    ##
    # Esegue un refresh della lista dei manager, ciclando su tutti i nodi, e scrivendo in /tmp un file temporaneo con
    # con la lista dei nomi dei managers
    def refresh_managers_cache_list
      list = self.nodes.select(&:manager?).collect { |c| Manager.new(name: c.name, connection_uri: c.connection_uri) }
      File.open(swarm_manager_cache_path, "w") do |f|
        list.collect(&:name).each do |name|
          f.puts(name)
        end
      end
    end

    def read_managers_cache_list
      # TODO sarebbe da aggiornare ogni tanto, metti che uno non spegne mai il pc
      refresh_managers_cache_list unless File.exists?(swarm_manager_cache_path)
      File.read(swarm_manager_cache_path).split("\n")
    end

    ##
    # Lista di tutti i nodi del cluster
    #
    # @return [Array<SwarmClusterCliOpe::Node>]
    def nodes
      @_nodes ||= Hash.new do |hash, key|
        hash[key] = self.merged_configurations[:connections_maps].collect { |m, c| Node.new(name: m.to_s, connection_uri: c) }
      end
      @_nodes[environment]
    end

    ##
    # Lista di nodi da assegnare alle configurazioni
    #
    # @param [Array<SwarmClusterCliOpe::Node>]
    # @return [Configuration]
    def nodes=(objs)
      nodes[environment] = objs
      self
    end

    ##
    # Salva le configurazioni base in HOME
    def save_base_cfgs
      super do |obj|
        obj.merge({connections_maps: nodes.collect { |k| [k.name, k.connection_uri] }.to_h})
      end
    end


    # @return [SwarmClusterCliOpe::Node]
    # @param [String] node nome del nodo
    def get_node(node)
      nodes.find { |c| c.name == node }
    end

    # @return [SwarmClusterCliOpe::Node]
    # @param [String] node_id
    def get_node_by_id(node_id)
      nodes.find { |c| c.id == node_id }
    end


    private


    def evaluate_correct_command_usage(configuration)

      if configuration[:connections_maps].keys.include?(:context)
        puts "ATTENZIONE, I COMANDI DEVONO ESSERE LANCIATI DAL SUB COMANDO K8S"
        exit
      end

    end


    ##
    # Path al file dove salviamo la cache dei managers, ha un TTL legato all'orario (anno-mese-giorno-ora)
    # quindi ogni ora si autoripulisce e con un md5 delle configurazioni di base
    # @return [String]
    def swarm_manager_cache_path
      md5 = Digest::MD5.hexdigest(self.merged_configurations.to_json)
      file_name = Time.now.strftime(".swarm_cluster_cli_manager_cache-%Y%m%d%H-#{md5}")
      File.join("/tmp", file_name)
    end


  end
end
