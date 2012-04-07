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
        @type = Howler::Config[:log] || 'info'
        @log = [who.to_s]
      end

      def info(message)
        @log << "INFO: #{message}"
        true
      end

      def debug(message)
        return false if @type != 'debug'
        message = "DBUG: #{message}"
        @log << message
        true
      end

      def flush
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
