module Sym
  class Message::Retry
    attr_accessor :at, :ttl

    def initialize(options = {})
      @at = options[:at]
      @at ||= Time.now.utc + (options[:after] || 5)
      @ttl = (Time.now.utc + options[:ttl]) if options[:ttl]
      @ttl ||= 0
    end
  end
end
