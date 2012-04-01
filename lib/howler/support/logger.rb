require 'logger'

module Howler
  class Logger
    def initialize
      @logger = ::Logger.new(STDOUT)
      @logger.formatter = Howler::Logger::DefaultFormatter
    end

    def info(message)
      @logger.info(message)
    end

    def debug(message)
      @logger.debug(message)
    end

    def log(who = "#<Worker id: 0 name: 'supervisor'>")
      logger = Logger::Proxy.new(who)
      yield logger
      content = logger.flush
      @logger.info(content) if content
    end

    private

    class Logger::Proxy
      def initialize(who)
        @type = Howler::Manager.current[:log] || 'info'
        @log = ["A Logging block from: #{who}"]
        @debug = []
      end

      def info(message)
        @log << "INFO: #{message.to_s}"
        true
      end

      def debug(message)
        message = "DBUG: #{message.to_s}"
        @log << message
        @debug << message
        true
      end

      def flush
        @log = (@log - @debug) unless @type == 'debug'
        return unless @log.size > 1
        @log.join("\n   ")
      end
    end
  end

  class Logger::DefaultFormatter < ::Logger::Formatter
    def self.call(sev, time, program, message)
      "[#{time.strftime('%Y-%m-%d %H:%I:%M:%9N')}] - #{message.to_s}\n"
    end
  end
end
