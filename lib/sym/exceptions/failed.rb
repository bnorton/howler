module Sym
  class Message::Failed < Message::Error

    def initialize(*)
      super
      @message ||= "Message Failed at " + Sym::Util.now
    end
  end
end
