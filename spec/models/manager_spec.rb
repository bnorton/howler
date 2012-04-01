require "spec_helper"

describe Howler::Manager do
  before do
    subject.stub(:sleep)
  end

  describe ".current" do
    it "should return the current manager instance" do
      Howler::Manager.current.class.should == Howler::Manager
    end
  end

  describe "#run!" do
    describe "when there are no pending messages" do
      class SampleEx < Exception; end

      describe "when there are no messages" do
        it "should sleep for one second" do
          subject.should_receive(:sleep).with(1).and_raise(SampleEx)

          expect {
            subject.run!
          }.to raise_error(SampleEx)
        end
      end
    end

    describe "when there are pending messages" do
      let(:util) { mock(Howler::Util) }
      let!(:worker) { mock(Howler::Worker, :perform => nil) }
      let!(:message) { mock(Howler::Message) }

      before do
        subject.stub(:done?).and_return(false, false, true)
        2.times { subject.push(Howler::Util, :length, [1,2,3]) }

        Howler::Util.stub(:new).and_return(util)
        Howler::Message.stub(:new).and_return(message)
        Howler::Worker.stub(:new).and_return(worker)
      end

      it "should not sleep" do
        subject.should_not_receive(:sleep)

        subject.run!
      end

      it "should remove the message from redis" do
        Howler.send(:_redis).should_receive(:zrange).twice
        Howler.send(:_redis).should_receive(:zremrangebyrank).twice

        subject.run!
      end

      it "should ask a new worker to process the message" do
        subject.stub(:done?).and_return(false, true)
        worker.should_receive(:perform).with(message, Howler::Queue::DEFAULT)

        subject.run!
      end
    end
  end

  describe "[]" do
    before do
      subject.send(:options)[:synchronous] = true
    end

    it "should configure options" do
      subject[:synchronous].should == true
    end
  end

  describe "#[]=" do
    before do
      subject[:synchronous] = true
    end

    it "should configure options" do
      subject.send(:options)[:synchronous].should == true
    end
  end

  describe "#done?" do
    describe "when the done option is set" do
      before do
        subject[:done] = true
      end

      it "should return true" do
        subject.done?.should == true
      end
    end

    describe "when the done option is not set" do
      before do
        subject.send(:options).delete(:done)
      end

      it "should return false" do
        subject.done?.should == false
      end
    end

  end

  describe "#push" do
    let!(:queue) { Howler::Queue.new(Howler::Manager::DEFAULT) }

    def create_message(klass, method, args)
      {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }
    end

    before do
      Howler::Queue.stub(:new).and_return(queue)
    end

    describe "when given a class, method, and name" do
      it "should push a message" do
        Timecop.freeze(DateTime.now) do
          message = create_message("Array", :length, [1234])
          queue.should_receive(:push).with(message)

          subject.push(Array, :length, [1234])
        end
      end

      it "should enqueue the message" do
        should_change(Howler::Manager::DEFAULT).length_by(1) do
          subject.push(Array, :length, [1234])
        end
      end
    end
  end
end
