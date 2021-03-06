require "spec_helper"

describe Howler::Message::Notify do
  let!(:ex) { generate_exception }
  subject { Howler::Message::Notify.new(ex) }

  it "should inherit from Howler::Message::Error" do
    Howler::Message::Notify.ancestors.should include(Howler::Message::Error)
  end

  describe "#cause" do
    it "should store the cause" do
      subject.cause.should == ex
    end
  end

  describe "#env" do
    it "should store the hostname" do
      subject.env['hostname'].should == `hostname`.chomp
    end

    it "should store the ruby version" do
      subject.env['ruby_version'].should == `ruby -v`.chomp
    end
  end

  describe "#to_s" do
    let!(:subj) { begin; raise subject; rescue Exception => e; e; end}

    it "should have the allowed attributes" do
      subject.to_s.should == "Exception from #{subject.env['hostname']}\n\n#{subject.backtrace.join("\n")}"
    end
  end
end
