require 'thor'
module SwarmClusterCliOpe

  class Cli < Thor
    include LoggerConcern

    def self.exit_on_failure?
      true
    end

    desc "foo", "Prints foo"

    def foo
      puts "foo"
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