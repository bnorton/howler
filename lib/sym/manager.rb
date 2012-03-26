module Sym
  class Manager
    DEFAULT = "pending:default"

    def self.run!
      loop do
        break if done?

        if (message = Sym.redis.with {|redis| redis.lpop(DEFAULT) })
          message = Sym::Message.new(MultiJson.decode(message))

          Sym::Worker.new.perform(message, Sym::Queue::DEFAULT)
        else
          sleep(1)
        end
      end
    end

    def self.push(klass, method, args)
      queue = Sym::Queue.new(DEFAULT)

      message = {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }

      queue.push(message)
    end

    def self.done?
      !!Sym::Manager[:done]
    end

    def self.[](key)
      (@options ||= {})[key]
    end

    def self.[]=(key, value)
      (@options ||= {})[key] = value
    end

    private

    def self.options
      @options ||= {}
    end
  end
end
