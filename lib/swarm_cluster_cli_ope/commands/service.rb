module SwarmClusterCliOpe
  module Commands
    class Service < Base

      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      # @param [String] stack_name nome dello stack da filtrare
      def ls(stack_name: nil)
        command do |cmd|
          cmd.add("service ls")
          cmd.add("--filter=\"label=com.docker.stack.namespace=#{stack_name}\"") if stack_name
        end.execute
      end

      ##
      # Ricarca il servizio per nome, nel caso in cui abbiamo anche il nome dello stack, concateniamo il nome
      # del servizio con lo stack (dato che è il sistema con cui è più semplice trovare un servizio di uno stack).
      # sucessivamente troviamo tutti i containers legati a quel servizio ed estrapoliamo l'istanza del primo
      # @param [String] service_name
      # @param [String] stack_name optional
      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      def find(service_name, stack_name: nil)
        command do |cmd|
          cmd.add("service ls --filter=\"name=#{  stack_name ? "#{stack_name}_" : "" }#{service_name}\"")
        end.execute
      end

      ##
      # Esegue il ps per un determinato servizio
      # @param [String] service_name
      # @param [String] stack_name optional
      # @return [SwarmClusterCliOpe::ShellCommandResponse]
      # @param [TrueClass] only_active se si vuole avere solo quelli attivi
      def ps(service_name, stack_name: nil, only_active: true)
        command do |cmd|
          cmd.add("service ps  #{stack_name ? "#{stack_name}_" : "" }#{service_name}")
          cmd.add('-f "desired-state=running"') if only_active
        end.execute
      end

    end
  end
end