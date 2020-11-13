require 'open4'
require 'json'

module SwarmClusterCliOpe
  class ShellCommandExecution
    include LoggerConcern

    #@return [Array<String>] comando da eseguire
    attr_accessor :cmd

    # @param [Array<String>,String] cmd
    def initialize(cmd)
      cmd = cmd.split(" ") if cmd.is_a? String
      @cmd = cmd
    end

    # @return [SwarmClusterCliOpe::ShellCommandExecution]
    # @param [*String] append_command
    def add(*append_command)
      @cmd.append(append_command)
      self
    end

    class Failure < Error
      def initialize(cmd, error)
        super("[SYSTEM COMMAND FAILURE] #{cmd} -> #{error}")
      end
    end

    ##
    # Esegue il comando e ritorna STDOUT, altrimenti se va in errore esegue un raise
    # @return [ShellCommandResponse]
    # @param [FalseClass] allow_failure -> se impostato a true, ritorniamo risultato anche quando fallisce
    def execute(allow_failure: false)
      result = {
        stdout: nil,
        stderr: nil,
        pid: nil,
        status: nil
      }
      logger.info { "SHELL: #{string_command}" }
      result[:status] = Open4::popen4(string_command) do |pid, stdin, stdout, stderr|
        stdin.close

        result[:stdout] = stdout.read.strip
        result[:stderr] = stderr.read.strip
        result[:pid] = pid
      end

      unless allow_failure
        raise Failure.new(cmd, result[:stderr]) if (result[:status] && result[:status].exitstatus != 0)
      end

      logger.debug { "SHELL_RESPONSE: #{JSON.pretty_generate(result)}" }

      ShellCommandResponse.new(result)
    end

    ##
    # Stampa il comando
    # @return [String]
    def string_command
      @cmd.join(' ')
    end


  end
end