require 'logger'

module SwarmClusterCliOpe
  module LoggerConcern
    def logger
      return LoggerConcern.const_get("LOGGER") if LoggerConcern.const_defined?("LOGGER")
      logger = Logger.new(STDOUT)
      LoggerConcern.const_set("LOGGER", logger)
      logger.level = case BaseConfiguration.instance.logger_level
                     when "0"
                       Logger::ERROR
                     when "1"
                       Logger::WARN
                     when "2"
                       Logger::INFO
                     when "3"
                       Logger::DEBUG
                     else
                       Logger::ERROR
                     end

      logger
    end

  end
end