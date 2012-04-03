require 'multi_json'

module Howler
  class Manager
    DEFAULT = "pending:default"

    def self.current
      @current ||= Howler::Manager.new
    end

    def initialize
      @options = {}

      @workers = Howler::Config[:concurrency].times.collect do
        Howler::Worker.new
      end
    end

    def run!
      loop do
        break if done?
        scale_workers

        worker_count = [0, @workers.size - 1].max

        messages = []

        Howler.redis.with do |redis|
          range_messages = redis.zrange(DEFAULT, 0, worker_count)
          messages = redis.zrangebyscore(DEFAULT, '-inf', Time.now.to_f)

          if messages.size > worker_count
            messages = range_messages
          end

          redis.zremrangebyrank(DEFAULT, 0, messages.size - 1) unless messages.size == 0
        end

        sleep(1) unless messages.any?

        messages.each_with_index do |message, i|
          message = Howler::Message.new(MultiJson.decode(message))
          @workers[i].perform(message, Howler::Queue::DEFAULT)
        end
      end
    end

    def push(klass, method, args, wait_until = Time.now)
      queue = Howler::Queue.new(DEFAULT)

      message = {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }

      queue.push(message, wait_until)
    end

    def done?
      !!@done
    end

    private

    def scale_workers
      delta = (@workers.size - Howler::Config[:concurrency])
      if delta > 0
        delta.times { @workers.pop }
      elsif delta < 0
        delta.abs.times { @workers << Howler::Worker.new }
      end
    end
  end
end
