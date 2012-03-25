require 'redis'
require 'connection_pool'

require_relative 'sym/util'

require_relative 'sym/message'
require_relative 'sym/queue'
require_relative 'sym/worker'
require_relative 'sym/manager'

require_relative 'sym/async'

module Sym
  def self.redis
    @connection ||= ConnectionPool.new(:timeout => 1, :size => 5) { _redis }
  end

  private

  def self._redis
    @redis ||= ::Redis.connect(:url => 'redis://localhost:6379/0')
  end
end

Object.extend Sym::Async
