require "spec_helper"

describe Howler::Util do
  describe ".constantize" do
    it "should convert a string into a constant" do
      Howler::Util.constantize("Array").should == Array
      Howler::Util.constantize("Howler").should == Howler
      Howler::Util.constantize("::Howler").should == Howler
      Howler::Util.constantize("Howler::Util").should == Howler::Util
    end

    it "should raise a NameError" do
      expect {
        Howler::Util.constantize("a")
      }.to raise_error(NameError)
    end

    it "should raise a NoMethodError" do
      expect {
        Howler::Util.constantize(nil)
      }.to raise_error(NoMethodError)
    end
  end

  describe ".now"  do
    it "should be properly formatted" do
      Timecop.freeze(2012, 3, 24, 14, 30, 55) do
        Howler::Util.now.should == "Mar 24 2012 14:30:55"
      end
    end
  end

  describe ".at"  do
    it "should be properly formatted" do
      Timecop.freeze(2012, 3, 24, 14, 30, 55) do
        Howler::Util.at(Time.now.to_f).should == "Mar 24 2012 14:30:55"
      end
    end

    it "should handle a nil time" do
      Howler::Util.at(nil).should == ""
    end
  end
end
