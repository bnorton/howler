require "spec_helper"

describe Howler::Message::Error do
  it "should inherit from Exception" do
    Howler::Message::Error.ancestors.should include(Exception)
  end

  describe "#message" do
    it "should set the message" do
      subject.message = "1234"

      subject.message.should == "1234"
    end
  end

  describe "#backtrace" do
    it "should store a short backtrace" do
      begin
        raise Howler::Message::Error
      rescue Howler::Message::Error => e
        e.info['backtrace'].class.should == Array
        e.info['backtrace'].length.should == 8
      end
    end
  end

  describe "#info" do
    let!(:short_backtrace) { mock("short:backtrace") }
    let!(:backtrace) { mock("backtrace", :[] => short_backtrace ) }

    before do
      Howler::Message::Error.any_instance.stub(:backtrace).and_return(backtrace)
      Howler::Message::Error.any_instance.stub(:message).and_return("message")
    end

    begin
      raise Howler::Message::Error.new(:key => 'value', :another => 1)
    rescue Howler::Message::Error => e
      it "should store a short backtrace" do
        e.info['backtrace'].should == short_backtrace
      end

      it "should store the message" do
        e.info['message'].should == 'message'
      end

      it "should store arbitrary information" do
        e.info['key'].should == 'value'
        e.info['another'].should == 1
      end
    end
  end
end
