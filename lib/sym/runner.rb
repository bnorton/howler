module Sym
  class Runner
    def run
      @manager = Sym::Manager.new

      begin
        @manager.run!
      rescue Interrupt
      end
    end
  end
end
