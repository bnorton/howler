module Sym
  class Message
    attr_reader :klass, :method, :args, :created_at

    def initialize(message)
      raise ArgumentError, "A message requires a method" unless message['method']

      @klass = Sym::Util.constantize(message['class'])
      @method = message['method'].to_sym
      @args = message['args']
      @created_at = message['created_at'] || Time.now
    end
  end
end
