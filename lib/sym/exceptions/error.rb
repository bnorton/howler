module Sym
  class Message::Error < Exception
    attr_accessor :message

    def initialize(options = {})
      @info = {}

      options.each do |key, value|
        @info[key.to_s] = value
      end
    end

    def info
      @info.merge!(
        'backtrace' => self.backtrace[0..7]
      ) if self.backtrace && !@info['backtrace']

      @info.merge!(
        'message' => self.message
      ) unless @info['message']

      @info
    end
  end
end
