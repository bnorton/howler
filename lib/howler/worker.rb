require 'celluloid'

module Howler
  class Worker
    include Celluloid

    def perform(message, queue)
      queue = Howler::Queue.new(queue) unless queue.is_a?(Howler::Queue)

      queue.statistics(message.klass, message.method, message.args) do
        message.klass.new.send(message.method, *message.args)
      end

      Howler::Manager.current.done_chewing(current_actor)
    end
  end
end
