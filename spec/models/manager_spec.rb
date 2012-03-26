require "spec_helper"

describe Sym::Manager do
  describe ".run!" do
    describe "when there are no pending messages" do
      class SampleEx < Exception; end

      describe "when there are no messages" do
        it "should sleep for one second" do
          Sym::Manager.should_receive(:sleep).with(1).and_raise(SampleEx)

          expect {
            Sym::Manager.run!
          }.to raise_error(SampleEx)
        end
      end
    end

    describe "when there are pending messages" do
      let(:util) { mock(Sym::Util) }

      before do
        Sym::Manager.stub(:done?).and_return(false, false, true)
        2.times { Sym::Manager.push(Sym::Util, :length, [1,2,3]) }

        Sym::Util.stub(:new).and_return(util)
      end

      it "should not sleep" do
        Sym::Manager.should_not_receive(:sleep)

        Sym::Manager.run!
      end

      it "should process the pending messages" do
        util.should_receive(:length).twice.with(1,2,3)

        Sym::Manager.run!
      end
    end
  end

  describe "[]" do
    before do
      Sym::Manager.send(:options)[:synchronous] = true
    end

    it "should configure options" do
      Sym::Manager[:synchronous].should == true
    end
  end

  describe "[]=" do
    before do
      Sym::Manager[:synchronous] = true
    end

    it "should configure options" do
      Sym::Manager.send(:options)[:synchronous].should == true
    end
  end

  describe ".done?" do
    describe "when the done option is set" do
      before do
        Sym::Manager[:done] = true
      end

      it "should return true" do
        Sym::Manager.done?.should == true
      end
    end

    describe "when the done option is not set" do
      before do
        Sym::Manager.send(:options).delete(:done)
      end

      it "should return false" do
        Sym::Manager.done?.should == false
      end
    end

  end

  describe ".push" do
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

          Sym::Manager.push(Array, :length, [1234])
        end
      end

      it "should enqueue the message" do
        should_change(Sym::Manager::DEFAULT).length_by(1) do
          Sym::Manager.push(Array, :length, [1234])
        end
      end
    end

    describe "when specifying a queue" do
      let(:message) { create_message(Array, :length, [1234]) }

      it "should push to the default queue" do
        Timecop.freeze(DateTime.now) do
          queue.should_receive(:push).with(message)

          Sym::Manager.push(Array, :length, [1234])
        end
      end

      describe "when given the queue parameter" do
        it "should push to pending:(given queue)" do
          Timecop.freeze(DateTime.now) do
            Sym::Queue.should_receive(:new).with("pending:a_queue")
            queue.should_receive(:push).with(message)

            Sym::Manager.push(Array, :length, [1234], "a_queue")
          end
        end

        it "should create a new queue with the given queue" do
          Sym::Queue.should_receive(:new).with("pending:a_queue")

          Sym::Manager.push(Array, :length, [1234], "a_queue")
        end
      end
    end
  end
end
