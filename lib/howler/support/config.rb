module Howler
  class Config
    WHITELIST = %w(concurrency)

    def self.[](key)
      Howler.redis.with {|redis| redis.hget("howler:config", key.to_s) }
    end

    def self.[]=(key, value)
      Howler.redis.with {|redis| redis.hset("howler:config", key.to_s, value) }
      value
    end

    def self.flush
      Howler.redis.with do |redis|
        keys = redis.hkeys("howler:config") - WHITELIST
        keys.each do |key|
          redis.hdel("howler:config", key)
        end
      end
    end
  end
end
