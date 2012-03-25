module Sym
  class Worker
    def perform(msg, queue_name)
      queue = Sym::Queue.new(queue_name)

      queue.statistics(msg.klass, msg.method, msg.args) do
        msg.klass.new.send(msg.method, *msg.args)
      end
    end
  end
end
