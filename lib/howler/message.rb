module Howler
  class Message
    attr_reader :id, :klass, :method, :args, :created_at

    def initialize(message)
      raise ArgumentError, "A message requires a method" unless message['method']

      @id = message['id']
      @klass = Howler::Util.constantize(message['class'])
      @method = message['method'].to_sym
      @args = message['args']
      @created_at = message['created_at'] || Time.now.to_f
    end
  end
end
