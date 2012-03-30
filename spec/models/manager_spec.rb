require "spec_helper"

describe Sym::Manager do
  before do
    subject.stub(:sleep)
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
      let(:util) { mock(Sym::Util) }
      let!(:worker) { mock(Sym::Worker, :perform => nil) }
      let!(:message) { mock(Sym::Message) }

      before do
        subject.stub(:done?).and_return(false, false, true)
        2.times { subject.push(Sym::Util, :length, [1,2,3]) }

        Sym::Util.stub(:new).and_return(util)
        Sym::Message.stub(:new).and_return(message)
        Sym::Worker.stub(:new).and_return(worker)
      end

      it "should not sleep" do
        subject.should_not_receive(:sleep)

        subject.run!
      end

      it "should remove the message from redis" do
        Sym.send(:_redis).should_receive(:zrange).twice
        Sym.send(:_redis).should_receive(:zremrangebyrank).twice

        subject.run!
      end

      it "should ask a new worker to process the message" do
        subject.stub(:done?).and_return(false, true)
        worker.should_receive(:perform).with(message, Sym::Queue::DEFAULT)

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
    let!(:queue) { Sym::Queue.new(Sym::Manager::DEFAULT) }

    def create_message(klass, method, args)
      {
        :class => klass.to_s,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }
    end

    before do
      Sym::Queue.stub(:new).and_return(queue)
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
        should_change(Sym::Manager::DEFAULT).length_by(1) do
          subject.push(Array, :length, [1234])
        end
      end
    end
  end
end
