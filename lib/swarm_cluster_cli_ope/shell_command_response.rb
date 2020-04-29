require 'forwardable'

module SwarmClusterCliOpe
##
# Identifica una risposta dalla shell
  class ShellCommandResponse
    extend Forwardable
    include LoggerConcern

    #@return [String]
    attr_accessor :raw_result

    # @param [Hash] result composto da:
    #    stdout: [String],
    #    stderr: [String],
    #    pid: [Integer],
    #    status: [Process::Status]
    def initialize(result)
      @raw_result = result
    end

    # ##
    # # Ritorna una versione stampabile del risultato
    # def to_s
    #   raw_result[:stdout]
    # end
    #
    ##
    # Risultato, essendo sempre composto da una lista di righe in formato json, ritorniamo un array di json
    # @param [Object] object_class
    # @return [Array<object_class>]
    def result(object_class: Hash)
      raw_result[:stdout].split("\n").collect { |s| object_class.new(JSON.parse(s)) }
    end

    #
    # def to_a
    #   raw_result[:stdout].split("\n")
    # end

    ##
    # Controlla se il valore di status è diverso da 0
    def failed?
      raw_result[:status].exitstatus.to_i != 0
    end

    ##
    # Ritorna l'errore della shell
    def stderr
      raw_result[:stderr]
    end

    # ##
    # # Quando il risultato è json, ritorniamo l'hash
    # def from_json
    #   JSON.parse(raw_result[:stdout])
    # end

    def_delegators :result, :collect, :last, :find
  end
end