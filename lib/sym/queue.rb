module Sym
  class Queue
    INDEX = "queues"
    DEFAULT = "default"

    attr_reader :id, :name, :created_at

    def initialize(identifier = DEFAULT)
      @id = identifier
      @name = "queues:" + identifier

      after_initialize
    end

    def push(message)
      message = MultiJson.encode(message)

      !!Sym.redis.with {|redis| redis.rpush(Sym::Manager::DEFAULT, message) }
    end

    def immediate(message)
      Sym::Worker.new.perform(message, self)
    end

    def statistics(klass = nil, method = nil, args = nil, created_at = nil, &block)
      Sym.redis.with {|redis| redis.hincrby(name, klass.to_s, 1) } if klass
      Sym.redis.with {|redis| redis.hincrby(name, "#{klass}:#{method}", 1) } if method

      metadata = {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :time => {},
        :created_at => created_at,
        :status => 'success'
      }

      begin
        time = Benchmark.measure do
          block.call
        end

        metadata.merge!(:time => parse_time(time))

        Sym.redis.with {|redis| redis.hincrby(name, "success", 1) }
      rescue Sym::Message::Retry => e_retry
        metadata[:status] = 'retry'
        unless e_retry.ttl != 0 && e_retry.ttl < Time.now
          Sym.redis.with {|redis| redis.zadd(name, e_retry.at.to_f, MultiJson.encode(metadata))}
        end
      rescue Exception => e
        metadata[:status] = 'error'
        Sym.redis.with {|redis| redis.hincrby(name, "error", 1) }
      end

      Sym.redis.with {|redis| redis.zadd("#{name}:messages", Time.now.to_f, MultiJson.encode(metadata))}
    end

    def pending_messages
      Sym.redis.with {|redis| redis.lrange(Sym::Manager::DEFAULT, 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def processed_messages
      Sym.redis.with {|redis| redis.zrange("#{name}:messages", 0, 100) }.collect do |message|
        MultiJson.decode(message)
      end
    end

    def success
      Sym.redis.with {|redis| redis.hget(name, "success") }.to_i
    end

    def error
      Sym.redis.with {|redis| redis.hget(name, "error") }.to_i
    end

    def created_at
      @created_at ||= Time.at(Sym.redis.with {|redis| redis.hget(name, "created_at") }.to_i)
    end

    private

    def after_initialize
      Sym.redis.with do |redis|
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
