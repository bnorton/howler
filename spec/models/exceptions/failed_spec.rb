require "spec_helper"

describe Sym::Message::Failed do
  it "should inherit from Sym::Message::Error" do
    Sym::Message::Failed.ancestors.should include(Sym::Message::Error)
  end

  describe "#message" do
    it "should have a default message" do
      Timecop.freeze(DateTime.now) do
        subject.message.should == "Message Failed at #{Sym::Util.now}"
      end
    end
  end
end
