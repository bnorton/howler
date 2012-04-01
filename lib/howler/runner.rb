module Howler
  class Runner
    def run
      require "./config/environment.rb"
      @manager = Howler::Manager.current

      begin
        @manager.run!
      rescue Interrupt
      end
    end
  end
end
