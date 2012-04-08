require 'spec_helper'

describe Howler::Worker do
  describe "#perform" do
    let!(:queue) { Howler::Queue.new }

    def build_message
      Howler::Message.new(
        "class" => "Howler",
        "method" => "length",
        "args" => [1234]
      )
    end

    before do
      Howler::Manager.current.wrapped_object.stub(:done_chewing)
      Howler::Queue.stub(:new).and_return(queue)
      @message = build_message
    end

    it "should setup a Queue with the given queue name" do
      Howler::Queue.should_receive(:new).with("a_queue")

      subject.perform(@message, "a_queue")
    end

    it "should log statistics" do
      queue.should_receive(:statistics).with(Howler, :length, [1234])

      subject.perform(@message, "a_queue")
    end

    it "should execute the given message" do
      array = mock(Howler)
      Howler.should_receive(:new).and_return(array)

      array.should_receive(:length).with(1234)

      subject.perform(@message, "a_queue")
    end

    it "should use the specified queue" do
      Howler::Queue.should_not_receive(:new)

      subject.perform(@message, queue)
    end

    it "should register with the manager when done" do
      Howler::Manager.current.wrapped_object.should_receive(:done_chewing).with(subject)

      subject.perform(@message, "a_queue")
    end
  end
end
