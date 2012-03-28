require 'spec_helper'

describe Sym::Worker do
  describe "#perform" do
    let!(:queue) { Sym::Queue.new }

    def build_message
      Sym::Message.new(
        "class" => "Sym",
        "method" => "length",
        "args" => [1234]
      )
    end

    before do
      Sym::Queue.stub(:new).and_return(queue)
      @message = build_message
    end

    it "should setup a Queue with the given queue name" do
      Sym::Queue.should_receive(:new).with("AQueue")

      subject.perform(@message, "AQueue")
    end

    it "should log statistics" do
      queue.should_receive(:statistics).with(Sym, :length, [1234])

      subject.perform(@message, "AQueue")
    end

    it "should execute the given message" do
      array = mock(Sym)
      Sym.should_receive(:new).and_return(array)

      array.should_receive(:length).with(1234)

      subject.perform(@message, "AQueue")
    end

    it "should use the specified queue" do
      Sym::Queue.should_not_receive(:new)

      subject.perform(@message, queue)
    end
  end
end
