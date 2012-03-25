module Sym
  class Message
    attr_reader :klass, :method, :args

    def initialize(message)
      raise ArgumentError, "A message requires a method" unless message['method']

      @klass = Sym::Util.constantize(message['class'])
      @method = message['method'].to_sym
      @args = message['args']
    end
  end
end
