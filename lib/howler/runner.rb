Howler::Config[:concurrency] = 1
Howler::Config[:shutdown_timeout] = 5

module Howler
  class Runner
    def run
      require "./config/environment.rb"
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
  end
end
