require "spec_helper"

describe Sym::Util do
  describe ".constantize" do
    it "should convert a string into a constant" do
      Sym::Util.constantize("Array").should == Array
      Sym::Util.constantize("Sym").should == Sym
      Sym::Util.constantize("::Sym").should == Sym
      Sym::Util.constantize("Sym::Util").should == Sym::Util
    end

    it "should raise a NameError" do
      expect {
        Sym::Util.constantize("a")
      }.to raise_error(NameError)
    end

    it "should raise a NoMethodError" do
      expect {
        Sym::Util.constantize(nil)
      }.to raise_error(NoMethodError)
    end
  end

  describe ".now"  do
    it "should be properly formatted" do
      Timecop.freeze(2012, 3, 24, 14, 30, 55) do
        Sym::Util.now.should == "Mar 24 2012 14:30:55"
      end
    end
  end

  describe ".at"  do
    it "should be properly formatted" do
      Timecop.freeze(2012, 3, 24, 14, 30, 55) do
        Sym::Util.at(Time.now.to_f).should == "Mar 24 2012 14:30:55"
      end
    end

    it "should handle a nil time" do
      Sym::Util.at(nil).should == ""
    end
  end
end
