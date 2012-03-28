module Sym
  class Message::Retry < Sym::Message::Error
    attr_accessor :at, :ttl

    def initialize(options = {})
      @at = options[:at]
      @at ||= Time.now.utc + (options[:after] || 300)
      @ttl = (Time.now.utc + options[:ttl]) if options[:ttl]
      @ttl ||= 0
    end
  end
end
