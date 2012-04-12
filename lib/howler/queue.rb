module Howler
  class Queue
    INDEX = "queues"
    DEFAULT = "default"

    attr_reader :id, :name, :created_at

    def initialize(identifier = DEFAULT)
      @id = identifier
      @name = "queues:" + identifier
      @logger = Howler::Logger.new

      after_initialize
    end

    def push(message, time = Time.now)
      message = MultiJson.encode(message)

      Howler.redis.with {|redis| redis.zadd(Howler::Manager::DEFAULT, time.to_f, message) } != 0
    end

    def immediate(message)
      Howler::Worker.new.perform(message, self)
    end

    def statistics(klass = nil, method = nil, args = nil, created_at = nil, &block)
      Howler.redis.with {|redis| redis.hincrby(name, klass.to_s, 1) } if klass
      Howler.redis.with {|redis| redis.hincrby(name, "#{klass}:#{method}", 1) } if method

      metadata = {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :time => {},
        :created_at => created_at,
        :status => 'success'
      }

      @logger.log do |log|
        begin
          time = Benchmark.measure do
            block.call
          end
          metadata.merge!(:time => parse_time(time))
          Howler.redis.with {|redis| redis.hincrby(name, "success", 1) }
        rescue Howler::Message::Retry => e
          log.debug("Howler::Message::Retry - #{klass}.new.#{method}(#{Howler.args(args)})")
          requeue(metadata, e)
        rescue Howler::Message::Failed => e
          log.debug("Howler::Message::Failed - #{klass}.new.#{method}(#{Howler.args(args)})")
          failed(metadata, e)
        rescue Howler::Message::Notify => e
          log.debug("Howler::Message::Notify - #{klass}.new.#{method}(#{Howler.args(args)})")
          notify(metadata, e)
        rescue Exception => e
          log.debug("#{e.to_s} - #{klass}.new.#{method}(#{Howler.args(args)})")
          metadata[:status] = 'error'
          Howler.redis.with {|redis| redis.hincrby(name, "error", 1) }
        end
      end

      Howler.redis.with {|redis| redis.zadd("#{name}:messages", Time.now.to_f, MultiJson.encode(metadata)) } if %w(success error).include?(metadata[:status])
    end

    def pending_messages
      Howler.redis.with {|redis| redis.zrange(Howler::Manager::DEFAULT, 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def processed_messages
      Howler.redis.with {|redis| redis.zrange("#{name}:messages", 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def failed_messages
      Howler.redis.with {|redis| redis.zrange("#{name}:messages:failed", 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def self.notifications
      Howler.redis.with {|redis| redis.lrange("notifications", 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def success
      Howler.redis.with {|redis| redis.hget(name, "success") }.to_i
    end

    def error
      Howler.redis.with {|redis| redis.hget(name, "error") }.to_i
    end

    def created_at
      @created_at ||= Time.at(Howler.redis.with {|redis| redis.hget(name, "created_at") }.to_i)
    end

    private

    def requeue(message, e)
      message[:status] = 'retrying'
      unless e.ttl != 0 && e.ttl < Time.now
        Howler.redis.with {|redis| redis.zadd(Howler::Manager::DEFAULT, e.at.to_f, MultiJson.encode(message))}
      end
    end

    def failed(message, e)
      message[:status] = 'failed'
      message[:cause] = e
      message[:failed_at] = Time.now.to_f
      Howler.redis.with {|redis| redis.zadd("#{name}:messages:failed", Time.now.to_f, MultiJson.encode(message)) }
    end

    def notify(message, e)
      message[:status] = 'notified'
      message[:cause] = e
      Howler.redis.with {|redis| redis.lpush("notifications", MultiJson.encode(message)) }
    end

    def after_initialize
      Howler.redis.with do |redis|
        redis.sadd(INDEX, @id)
        redis.hsetnx(name, "created_at", Time.now.to_i)
      end
    end

    def parse_time(time)
      time = time.to_s.gsub(/[\(\)]/, '').split(/\s+/)
      {
        :system => time[2].to_f,
        :user => time[3].to_f
      }
    end
  end
end
