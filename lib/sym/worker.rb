module Sym
  class Worker
    def perform(message, queue)
      queue = Sym::Queue.new(queue) unless queue.is_a?(Sym::Queue)

      queue.statistics(message.klass, message.method, message.args) do
        message.klass.new.send(message.method, *message.args)
      end
    end
  end
end
