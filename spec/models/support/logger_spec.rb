require "spec_helper"

describe Howler::Logger do
  let!(:logger) { mock(Logger, :info => nil, :formatter= => nil) }

  before do
    Logger.stub(:new).and_return(logger)
  end

  describe ".new" do
    it "should log to stdout" do
      Logger.should_receive(:new).with(STDOUT)

      Howler::Logger.new
    end

    it "should use a custom formatter" do
      logger.should_receive(:formatter=).with(Howler::Logger::DefaultFormatter)

      Howler::Logger.new
    end

    describe "when there is log output" do
      let!(:logger) { Logger.new(STDOUT) }

      before do
        Logger.stub(:new).and_return(logger)
      end
    end
  end

  describe "#info" do
    describe "when called with a message" do
      it "should log to info" do
        logger.should_receive(:info).with("A pertinent piece of information.")

        subject.info("A pertinent piece of information.")
      end
    end
  end

  describe "#debug" do
    describe "when called with a message" do
      it "should log to debug" do
        logger.should_receive(:debug).with("A pertinent piece of debug information.")

        subject.debug("A pertinent piece of debug information.")
      end
    end
  end

  describe "#log" do
    let(:worker) { "#<Worker id: 1>" }

    describe "when given a block" do
      describe "when on the main process" do
        it "should log to the main process" do
          logger.should_receive(:info).with("#<Worker id: 0 name: 'supervisor'>\n   INFO: A supervisor level information bite.")

          subject.log do |log|
            log.info("A supervisor level information bite.")
          end
        end
      end

      it "should log information" do
        logger.should_receive(:info).with("#<Worker id: 1>\n   INFO: A pertinent piece of information.")

        subject.log(worker) do |log|
          log.info("A pertinent piece of information.")
        end
      end

      describe "debugging" do
        before do
          Howler::Config[:log] = 'debug'
        end

        it "should be true" do
          subject.log(worker) do |log|
            log.debug("anything").should == true
          end
        end

        it "should log debugging information" do
          logger.should_receive(:info).with("#<Worker id: 1>\n   DBUG: A pertinent piece of debug information.")

          subject.log(worker) do |log|
            log.debug("A pertinent piece of debug information.")
          end
        end

        it "should log information and debugging information" do
          logger.should_receive(:info).with("#<Worker id: 1>\n   INFO: A pertinent piece of information.\n   DBUG: A pertinent piece of debug information.")

          subject.log(worker) do |log|
            log.info("A pertinent piece of information.")
            log.debug("A pertinent piece of debug information.")
          end
        end
      end

      describe "information" do
        before do
          Howler::Config[:log] = 'info'
        end

        it "should only log information" do
          logger.should_not_receive(:info)

          subject.log(worker) do |log|
            log.debug("It's a debug thing.")
          end
        end

        describe "when there is debugging" do
          it "should return false" do
            subject.log(worker) do |log|
              log.debug("It's a debug thing.").should == false
            end
          end

          it "should not store the debug string" do
            subject.log(worker) do |log|
              log.info("something")
              log.debug("It's a debug thing.")

              log.flush.should_not match(/It's a debug thing\./)
            end
          end
        end
      end
    end
  end
end

describe Howler::Logger::DefaultFormatter do
  describe ".call" do
    it "should have a compact format" do
      Timecop.freeze(DateTime.now) do
        format = Howler::Logger::DefaultFormatter.call(nil, Time.now, nil, "A Message")
        format.should =~ /\[#{Time.now.strftime('%Y-%m-%d %H:%I:%M:%9N')}\]/
        format.should =~ /A Message\n/
      end
    end
  end
end
