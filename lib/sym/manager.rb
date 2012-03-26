module Sym
  class Manager
    DEFAULT = "pending:default"

    def self.run!
      count = 0

      loop do
        break if done?

        if (message = Sym.redis.with {|redis| redis.lpop(DEFAULT) })
          message = Sym::Message.new(MultiJson.decode(message))

          Sym::Worker.new.perform(message, DEFAULT)
        end

        sleep(1)
      end
    end

    def self.push(klass, method, args, queue_name = DEFAULT)
      queue_name = ("pending:" + queue_name) unless /pending:/ === queue_name

      Sym::Queue.new(queue_name)

      message = MultiJson.encode(
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      )

      Sym.redis.with {|redis| redis.rpush(queue_name, message) }
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
