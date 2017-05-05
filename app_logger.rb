require 'logger'

class AppLoger
  LOG_LEVEL_INFO  = "info"
  LOG_LEVEL_DEBUG = "debug"
  LOG_LEVEL_ERROR = "error"

  class << self
    def setup descripter=STDOUT, level=nil
      @@log = Logger.new(descripter)
    end

    def trace(msg, level=LOG_LEVEL_DEBUG)
      caller_info = caller.first
      line = caller_info + msg
      @@log.send(level, line)
    end
  end
end
