require "spec_helper"

describe Howler::Runner do
  before do
    subject.stub(:require)
  end

  describe "#run" do
    let!(:manager) { Howler::Manager.current }

    before do
      Howler::Manager.stub(:current).and_return(manager)
      manager.stub(:run!)
    end

    it "should create a manager" do
      Howler::Manager.should_receive(:current)

      subject.run
    end

    it "should run the manager" do
      manager.should_receive(:run!)

      subject.run
    end

    it "should load the Rails 3 environment" do
      subject.should_receive(:require).with("./config/environment.rb")

      subject.run
    end

    describe "when the runner receives an Interrupt" do
      before do
        manager.stub(:run!).and_raise(Interrupt)
        Howler::Manager.current.stub(:chewing).and_return([])
      end

      it "should trap the interrupt" do
        expect {
          subject.run
        }.not_to raise_error
      end

      describe "logging" do
        let!(:plain_log) { Howler::Logger.new }
        let!(:log) { mock(Howler::Logger::Proxy, :info => nil, :debug => nil) }

        before do
          Howler::Logger.stub(:new).and_return(plain_log)
          plain_log.stub(:log).and_yield(log)

          Howler::Config[:shutdown_timeout] = 6
        end

        it "should log information" do
          log.should_receive(:info).with("INT - Stopping all workers")
          plain_log.should_receive(:info).with("INT - All workers have shut down - Exiting")

          subject.run
        end

        it "should log debugging" do
          log.should_receive(:debug).ordered.with("INT - 0 workers still working.")

          subject.run
        end

        describe "when there are workers still working" do
          before do
            Howler::Config[:concurrency] = 4

            @chewing = 1.times.collect { mock(Howler::Worker) }

            Howler::Manager.current.stub(:chewing).and_return(@chewing)
            Howler::Manager.current.stub(:shutdown).and_return(3)
          end

          it "should log the number of seconds it will wait" do
            log.should_receive(:info).with("INT - Waiting 6 seconds for workers to complete.")

            subject.run
          end

          it "should notify the user about the number of worker still working" do
            log.should_receive(:debug).with("INT - 3 workers were shutdown immediately.")
            log.should_receive(:debug).with("INT - 1 workers still working.")

            subject.run
          end
        end
      end
    end
  end
end
