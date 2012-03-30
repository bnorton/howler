module Sym
  class Runner
    def run
      require "./config/environment.rb"
      @manager = Sym::Manager.current

      begin
        @manager.run!
      rescue Interrupt
      end
    end
  end
end
