require 'redis'
require 'connection_pool'

require_relative 'sym/support/util'
require_relative 'sym/support/logger'

require_relative 'sym/message'
require_relative 'sym/queue'
require_relative 'sym/worker'
require_relative 'sym/manager'
require_relative 'sym/runner'

require_relative 'sym/async'

require_relative 'sym/exceptions'

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
