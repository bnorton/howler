module Howler
  class Runner
    attr_reader :options

    def initialize
      @options = {
        :concurrency => 30,
        :path => './config/environment.rb',
        :shutdown_timeout => 5
      }

      parse_options
      set_options
    end

    def run
      require Howler::Config[:path]
      @manager = Howler::Manager.current

      begin
        @manager.run!
        sleep
      rescue Interrupt
        logger = Howler::Logger.new

        still_working = @manager.chewing.size
        shutdown_timeout = Howler::Config[:shutdown_timeout]

        logger.log do |log|
          log.info("INT - Stopping all workers")

          log.debug("INT - #{@manager.shutdown} workers were shutdown immediately.")
          log.debug("INT - #{still_working} workers still working.")

          log.info("INT - Waiting #{shutdown_timeout} seconds for workers to complete.") if still_working > 0
        end

        sleep(shutdown_timeout.to_i) if still_working > 0

        logger.info("INT - All workers have shut down - Exiting")
      end
    end

    private

    def set_options
      Howler._redis @options[:redis_url]

      @options.each_pair do |option, value|
        Howler::Config[option] = value
      end
    end

    def parse_options
      OptionParser.new do |opts|
        opts.on('-k', '--key_value OPTIONS', 'Arbitrary key - values into Howler::Config [key:value,another:value]') do |kvs|
          kvs.split(',').each do |kv|
            kv = kv.split(':')
            @options[kv.first] = kv.last
          end
        end

        opts.on('-r', '--redis_url URL', 'The url of the Redis Server [redis://localhost:6379/0]') do |url|
          @options[:redis_url] = url
        end

        opts.on('-c', '--concurrency COUNT', 'The number of Workers [30]') do |c|
          @options[:concurrency] = c
        end

        opts.on('-p', '--path PATH', 'The path to the file to load [./config/environment.rb]') do |path|
          @options[:path] = path
        end

        opts.on('-s', '--shutdown_timeout SECONDS', 'The number of seconds to wait for workers to finish [5]') do |seconds|
          @options[:shutdown_timeout] = seconds
        end
      end.parse!
    end
  end
end
