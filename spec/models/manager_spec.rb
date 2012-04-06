require "spec_helper"

describe Howler::Manager do
  describe ".current" do
    before do
      subject.stub(:sleep)
    end

    it "should return the current manager instance" do
      Howler::Manager.current.class.should == Howler::Manager
    end
  end

  describe "#run!" do
    def build_message(klass, method)
      Howler::Message.new(
        'class' => klass.to_s,
        'method' => method,
        'args' => [],
        'created_at' => Time.now.to_f
      )
    end

    before do
      subject.stub(:done?).and_return(true)
      Howler::Config[:concurrency] = 10
    end

    it "should create workers" do
      Howler::Worker.should_receive(:new).exactly(10)

      subject.run!
    end

    describe "when there are no pending messages" do
      before do
        subject.stub(:done?).and_return(false, true)
        subject.stub(:sleep)
      end

      class SampleEx < Exception; end

      describe "when there are no messages" do
        it "should sleep for one second" do
          subject.should_receive(:sleep).and_raise(SampleEx)

          expect {
            subject.run!
          }.to raise_error(SampleEx)
        end
      end
    end

    describe "when there are pending messages" do
      before do
        Howler::Manager.stub(:current).and_return(subject)

        Howler::Config[:concurrency] = 3

        @workers = 3.times.collect do
          mock(Howler::Worker, :perform => nil)
        end

        subject.stub(:build_workers).and_return(@workers)

        @messages = {
          'length' => build_message(Array, :length),
          'collect' => build_message(Array, :collect),
          'max' => build_message(Array, :max),
          'to_s' => build_message(Array, :to_s)
        }

        %w(length collect max to_s).each do |method|
          Howler::Message.stub(:new).with(hash_including('method' => method)).and_return(@messages[method])
        end

        subject.stub(:sleep)

        subject.stub(:done?).and_return(false, true)
      end

      describe "when there are no messages in the queue" do
        it "should sleep" do
          subject.should_receive(:sleep)

          subject.run!
        end
      end

      describe "when there is a single message in the queue" do
        before do
          subject.push(Array, :length, [])
        end

        it "should not sleep" do
          subject.should_not_receive(:sleep)

          subject.run!
        end

        it "should perform the message on a worker" do
          @workers[2].should_receive(:perform).with(@messages['length'], Howler::Queue::DEFAULT)

          @workers[0].should_not_receive(:perform)
          @workers[1].should_not_receive(:perform)

          subject.run!
        end

        describe "when a message gets taken by a worker" do
          before do
            @original_workers = @workers.dup
          end

          it "should make the worker unavailable" do
            subject.run!

            subject.should have(2).workers
            subject.should have(1).chewing

            subject.workers.should == @original_workers.first(2)
            subject.chewing.should == @original_workers.last(1)
          end
        end
      end

      describe "when there are many messages in the queue" do
        before do
          [:length, :collect, :max].each do |method|
            subject.push(Array, method, [])
          end
        end

        describe "when there are more workers then messages" do
          it "should perform all messages" do
            @workers[2].should_receive(:perform).with(@messages['length'], anything)
            @workers[1].should_receive(:perform).with(@messages['collect'], anything)
            @workers[0].should_receive(:perform).with(@messages['max'], anything)

            subject.run!
          end
        end

        describe "when there are more messages then workers" do
          before do
            subject.stub(:done?).and_return(false, false, true)

            Howler::Config[:concurrency] = 2
          end

          it "should scale and only remove as many messages as workers" do
            @workers[0].unstub(:perform)

            @workers[1].should_receive(:perform).with(@messages['length'], anything)
            @workers[0].should_receive(:perform).with(@messages['collect'], anything)

            subject.run!
          end
        end

        describe "when messages are queued to be run in the future" do
          let!(:worker) { mock(Howler::Worker) }

          before do
            subject.stub(:done?).and_return(false, false, true)
            Howler::Config[:concurrency] = 4

            Howler::Worker.should_receive(:new).once.and_return(worker)

            subject.push(Array, :to_s, [], Time.now + 5.minutes)
          end

          it "should only enqueue messages that are scheduled before now" do
            Timecop.freeze(Time.now) do
              worker.should_receive(:perform).with(@messages['length'], anything).ordered
              @workers[2].should_receive(:perform).with(@messages['collect'], anything)
              @workers[1].should_receive(:perform).with(@messages['max'], anything)

              subject.run!

              subject.stub(:done?).and_return(false, true)

              Timecop.travel(5.minutes) do
                @workers[0].should_receive(:perform).with(@messages['to_s'], anything).ordered
                subject.run!
              end
            end
          end
        end
      end
    end
  end

  describe "#shutdown" do
    before do
      subject.stub(:done?).and_return(true)

      Howler::Config[:concurrency] = 2
      subject.instance_variable_set(:@chewing, [mock(Howler::Worker)])
    end

    it "should remove non active workers from the list" do
      subject.run!

      subject.should have(2).workers
      subject.should have(1).chewing

      subject.shutdown.should == 2

      subject.should have(0).workers
      subject.should have(1).chewing
    end
  end

  describe "#done?" do
    describe "when the done option is set" do
      before do
        subject.instance_variable_set(:@done, true)
      end

      it "should return true" do
        subject.done?.should == true
      end
    end

    describe "when the done option is not set" do
      before do
        subject.instance_variable_set(:@done, nil)
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
        :id => 123,
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
          queue.should_receive(:push).with(message, Time.now)

          subject.push(Array, :length, [1234])
        end
      end

      it "should enqueue the message" do
        should_change(Howler::Manager::DEFAULT).length_by(1) do
          subject.push(Array, :length, [])
        end
      end
    end

    describe "when given the 'wait until' time" do
      it "should enqueue the message" do
        should_change(Howler::Manager::DEFAULT).length_by(1) do
          subject.push(Array, :length, [], Time.now + 5.minutes)
        end
      end
    end
  end
end
