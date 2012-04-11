require 'redis'
require 'connection_pool'

module Howler
  def self.next(id)
    redis.with {|redis| redis.hincrby("next", id.to_s, 1) }.to_i
  end
  def self.args(args)
    args.to_s.gsub(/^\[|\]$/, '')
  end
  def self.redis
    @connection ||= ConnectionPool.new(:timeout => 1, :size => 30) { _redis }
  end
  private
  def self._redis(url = 'redis://localhost:6379/0')
    @redis ||= ::Redis.connect(:url => url, :thread_safe => true)
  end
end

require_relative 'howler/support/config'
require_relative 'howler/support/util'
require_relative 'howler/support/logger'

require_relative 'howler/message'
require_relative 'howler/queue'
require_relative 'howler/worker'
require_relative 'howler/manager'
require_relative 'howler/runner'

require_relative 'howler/async'

require_relative 'howler/exceptions'

Object.extend Howler::Async
