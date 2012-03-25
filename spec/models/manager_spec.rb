require "spec_helper"

describe Sym::Manager do
  describe ".run!" do
    describe "when there are no pending messages" do
      class SampleEx < Exception; end

      it "should sleep for one second" do
        Sym::Manager.should_receive(:sleep).with(1).and_raise(SampleEx)

        expect {
          Sym::Manager.run!
        }.to raise_error(SampleEx)
      end
    end

    describe "when there are pending messages" do
      let(:util) { mock(Sym::Util) }

      before do
        Sym::Manager.stub(:done?).and_return(false, false, true)
        2.times { Sym::Manager.push(Sym::Util, :length, [1,2,3]) }

        Sym::Util.stub(:new).and_return(util)
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
    def create_message(klass, method, args)
      {
        :class => klass,
        :method => method,
        :args => args,
        :created_at => Time.now.to_f
      }
    end

    describe "when given a class, method, and name" do
      it "should push a message" do
        Timecop.freeze(DateTime.now) do
          message = create_message(Array, :length, [1234])
          Sym.send(:_redis).should_receive(:rpush).with(anything, MultiJson.encode(message))

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
      let(:message) { MultiJson.encode(create_message(Array, :length, [1234])) }

      it "should push to the default queue" do
        Timecop.freeze(DateTime.now) do
          Sym.send(:_redis).should_receive(:rpush).with(Sym::Manager::DEFAULT, message)

          Sym::Manager.push(Array, :length, [1234])
        end
      end

      describe "when given the queue parameter" do
        it "should push to pending:(given queue)" do
          Timecop.freeze(DateTime.now) do
            Sym.send(:_redis).should_receive(:rpush).with("pending:a_queue", message)

            Sym::Manager.push(Array, :length, [1234], "a_queue")
          end
        end

        it "should add the queue to the set of queues" do
          Sym::Queue.should_receive(:new).with("pending:a_queue")

          Sym::Manager.push(Array, :length, [1234], "a_queue")
        end
      end
    end
  end
end
