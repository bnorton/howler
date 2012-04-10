module Howler
  class Config
    WHITELIST = %w(concurrency shutdown_timeout path_prefix).freeze

    def self.[](key)
      Howler.redis.with {|redis| redis.hget("howler:config", key.to_s) }
    end

    def self.[]=(key, value)
      if value.nil?
        delete(key)
        return
      end

      Howler.redis.with {|redis| redis.hset("howler:config", key.to_s, value) }
    end

    def self.flush
      Howler.redis.with do |redis|
        keys = redis.hkeys("howler:config") - WHITELIST
        keys.each do |key|
          redis.hdel("howler:config", key)
        end
      end
    end

    private

    def self.delete(key)
      Howler.redis.with {|redis| redis.hdel("howler:config", key.to_s) }
    end
  end
end
