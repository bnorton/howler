require 'logger'

module Sym
  class Logger
    def initialize
      ::Logger.new(STDOUT)
    end
  end
end
