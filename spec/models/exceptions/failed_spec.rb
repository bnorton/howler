require "spec_helper"

describe Howler::Message::Failed do
  it "should inherit from Howler::Message::Error" do
    Howler::Message::Failed.ancestors.should include(Howler::Message::Error)
  end

  describe "#message" do
    it "should have a default message" do
      Timecop.freeze(DateTime.now) do
        subject.message.should == "Message Failed at #{Howler::Util.now}"
      end
    end
  end
end
