require 'logger'

class AppLoger
  LOG_LEVEL_INFO  = "info"
  LOG_LEVEL_DEBUG = "debug"
  LOG_LEVEL_ERROR = "error"

  class << self
    def setup progname=nil, descripter=STDOUT, level=LOG_LEVEL_DEBUG
      @@logger = Logger.new(descripter)
      @@logger.datetime_format = '%Y-%m-%d %H:%M:%s'
      @@logger.formatter =
        proc { |severity, datetime, progname, msg| "[#{datetime}] [#{severity}] #{msg}\n"}
    end

    def trace(msg, level=LOG_LEVEL_DEBUG)
      caller_info = caller.first
      filename = File.basename(caller_info)
      line = filename + " " + msg
      @@logger.send(level, line)
    end

    def call_in
      caller_info = caller.first
      filename = File.basename(caller_info)
      line = filename + " " + "Called In..."
      @@logger.send(LOG_LEVEL_DEBUG, line)
    end

    def call_out
      caller_info = caller.first
      filename = File.basename(caller_info)
      line = filename + " " + "Called Out..."
      @@logger.send(LOG_LEVEL_DEBUG, line)
    end
  end
end
