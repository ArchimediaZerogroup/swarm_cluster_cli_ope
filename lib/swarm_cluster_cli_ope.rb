require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

require "active_support/core_ext/module/attribute_accessors"
module SwarmClusterCliOpe
  class Error < StandardError; end


  ##
  # La configurazione che viene resa disponibile a tutte le funzioni sucessivamente all'interazione con il concern
  # della configurazione o con il  blocco di configurazione di un determinato enviroment
  mattr_accessor :current_configuration
  @@current_configuration = nil

end
