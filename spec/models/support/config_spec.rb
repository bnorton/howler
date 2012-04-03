require "spec_helper"

describe Howler::Config do
  describe ".[]" do
    before do
      Howler::Config.class_eval("@@options")[:synchronous] = true
    end

    it "should configure options" do
      Howler::Config[:synchronous].should == true
    end
  end

  describe ".[]=" do
    before do
      Howler::Config[:done] = true
    end

    it "should configure options" do
      Howler::Config.class_eval("@@options")[:done].should == true
    end
  end
end
