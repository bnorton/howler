require 'celluloid'
require 'multi_json'

module Howler
  class Manager
    include Celluloid

    trap_exit :worker_death

    DEFAULT = "pending:default"

    attr_reader :workers, :chewing

    def self.current
      @current ||= Howler::Manager.new
    end

    def initialize
      @done = false
      @logger = Howler::Logger.new
      @options = {}
      @workers = []
      @chewing = []
    end

    def shutdown
      @done = true
      current_size = @workers.size
      @workers = []
      current_size
    end

    def run
      @workers = build_workers

      loop do
        break if done?
        scale_workers

        messages, range_messages = [], []

        Howler.redis.with do |redis|
          range_messages = redis.zrange(DEFAULT, 0, @workers.size - 1) if @workers.size > 0
          messages = redis.zrangebyscore(DEFAULT, '-inf', Time.now.to_f)

          if messages.size >= @workers.size
            messages = range_messages
          end

          redis.zremrangebyrank(DEFAULT, 0, messages.size - 1) unless messages.size == 0
        end

        @logger.log do |log|
          log.info("Processing #{messages.size} Messages")

          sleep(1) unless messages.any?

          messages.each do |message|
            message = Howler::Message.new(MultiJson.decode(message))
            log.debug("MESG - #{message.id} #{message.klass}.new.#{message.method}(#{Howler.args(message.args)})")

            worker = begin_chewing
            worker.perform!(message, Howler::Queue::DEFAULT)
          end
        end
      end
    end

    def push(klass, method, args, wait_until = Time.now)
      queue = Howler::Queue.new(DEFAULT)

      message = {
        :id => Howler.next(:id),
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }

      queue.push(message, wait_until)
    end

    def done?
      @done
    end

    def done_chewing(worker)
      worker = @chewing.delete(worker)
      @workers.push(worker) if worker.alive?
      nil
    end

    def worker_death(actor=nil, reason=nil)
      @chewing.delete(actor)
      @workers.push Howler::Worker.new_link
    end

    private

    def begin_chewing
      worker = @workers.pop
      @chewing.push worker
      worker
    end

    def build_workers
      Howler::Config[:concurrency].to_i.times.collect do
        Howler::Worker.new_link
      end
    end

    def scale_workers
      delta = ((@workers.size + @chewing.size) - Howler::Config[:concurrency].to_i)
      return if delta == 0

      if delta > 0
        [@workers.size, delta].min.times { @workers.pop }
      elsif delta < 0
        delta.abs.times { @workers.push Howler::Worker.new }
      end
    end
  end
end
