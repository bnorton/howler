require 'redis'
require 'connection_pool'

module Howler
  def self.redis
    @connection ||= ConnectionPool.new(:timeout => 1, :size => 5) { _redis }
  end
  private
  def self._redis
    @redis ||= ::Redis.connect(:url => 'redis://localhost:6379/0')
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
