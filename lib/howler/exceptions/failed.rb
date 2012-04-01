module Howler
  class Message::Failed < Message::Error

    def initialize(*)
      super
      @message ||= "Message Failed at " + Howler::Util.now
    end
  end
end
