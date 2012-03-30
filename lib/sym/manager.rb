require 'multi_json'

module Sym
  class Manager
    DEFAULT = "pending:default"

    def self.current
      @current ||= Sym::Manager.new
    end

    def initialize
      @options = {}
    end

    def run!
      loop do
        break if done?

        messages = Sym.redis.with do |redis|
          m = redis.zrange(DEFAULT, 0, 0)
          redis.zremrangebyrank(DEFAULT, 0, 0)
          m
        end

        if messages && messages.length > 0
          message = Sym::Message.new(MultiJson.decode(messages.first))

          Sym::Worker.new.perform(message, Sym::Queue::DEFAULT)
        else
          sleep(1)
        end
      end
    end

    def push(klass, method, args)
      queue = Sym::Queue.new(DEFAULT)

      message = {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }

      queue.push(message)
    end

    def done?
      !!@options[:done]
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end

    private

    def options
      @options
    end
  end
end
