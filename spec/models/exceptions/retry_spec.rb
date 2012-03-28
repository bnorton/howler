require "spec_helper"

describe Sym::Message::Retry do
  it "should inherit from Sym::Message::Error" do
    Sym::Message::Retry.ancestors.should include(Sym::Message::Error)
  end

  describe "#at" do
    subject { Sym::Message::Retry.new(:at => Time.now.utc + 1.day) }

    it "should store the retry at time" do
      Timecop.freeze(DateTime.now) do
        subject.at.should == Time.now.utc + 1.day
      end
    end

    describe "when given the after attribute" do
      subject { Sym::Message::Retry.new(:after => 5.minutes) }

      it "should set the retry at value" do
        Timecop.freeze(DateTime.now) do
          subject.at.should == Time.now.utc + 5.minutes
        end
      end
    end
  end

  describe "#ttl" do
    describe "when not given the ttl" do
      it "should default to zero" do
        subject.ttl.should == 0
      end
    end

    describe "when given the ttl" do
      subject { Sym::Message::Retry.new(:ttl => 5.days) }

      it "should store the ttl" do
        subject.ttl.should_not be_nil
      end

      it "should be the 'ttl' minutes in the future" do
        Timecop.freeze(DateTime.now) do
          subject.ttl.should == Time.now.utc + 5.days
        end
      end
    end
  end
end
