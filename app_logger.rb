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
      line = make_log(caller_info, msg)
      @@logger.send(level, line)
    end

    def call_in
      caller_info = caller.first
      line = make_log(caller_info, "In...")
      @@logger.send(LOG_LEVEL_DEBUG, line)
    end

    def call_out
      caller_info = caller.first
      line = make_log(caller_info, "Out...")
      @@logger.send(LOG_LEVEL_DEBUG, line)
    end

    private

    def make_log caller_info, msg
      info_list = caller_info.split(':')
      filename = File.basename(info_list[0])
      lineno = info_list[1]
      method_name = info_list[2].slice(/`.*'/)
      line = "[#{filename}]:[#{sprintf("%4d",lineno)}] #{method_name} #{msg}"
    end
  end
end
