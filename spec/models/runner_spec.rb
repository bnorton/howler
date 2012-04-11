require "spec_helper"

describe Howler::Runner do
  before do
    subject.stub(:require)
    subject.stub(:sleep)
  end

  describe ".new" do
    let!(:opts) { mock(OptionParser, :on => nil, :parse! => nil) }

    describe "parsing options" do
      before do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
      end

      it "should set up an options parser" do
        OptionParser.should_receive(:new)

        Howler::Runner.new
      end

      it "should parse the options" do
        opts.should_receive(:parse!)

        Howler::Runner.new
      end
    end

    describe "for the redis url" do
      before do
        ARGV.replace(['-r', 'anything'])
      end

      it "should setup the matcher" do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
        opts.should_receive(:on).with("-r", "--redis_url URL", "The url of the Redis Server [redis://localhost:6379/0]")

        Howler::Runner.new
      end

      it "should set the argument" do
        Howler::Runner.new.options[:redis_url].should == 'anything'
      end
    end

    describe "for custom key - values" do
      before do
        ARGV.replace(['-k', 'key:value,k:5'])
      end

      it "should setup the matcher" do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
        opts.should_receive(:on).with("-k", "--key_value OPTIONS", "Arbitrary key - values into Howler::Config [key:value,another:value]")

        Howler::Runner.new
      end

      it "should set the argument" do
        runner = Howler::Runner.new

        runner.options['key'].should == 'value'
        runner.options['k'].should == '5'
      end
    end

    describe "for concurrency" do
      before do
        ARGV.replace(['-c', '50'])
      end

      it "should setup the matcher" do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
        opts.should_receive(:on).with("-c", "--concurrency COUNT", "The number of Workers [30]")

        Howler::Runner.new
      end

      it "should set the argument" do
        Howler::Runner.new.options[:concurrency].should == '50'
      end
    end

    describe "for the path" do
      before do
        ARGV.replace(['-p', 'a/path/to/env.rb'])
      end

      it "should setup the matcher" do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
        opts.should_receive(:on).with("-p", "--path PATH", "The path to the file to load [./config/environment.rb]")

        Howler::Runner.new
      end

      it "should set the argument" do
        Howler::Runner.new.options[:path].should == 'a/path/to/env.rb'
      end
    end

    describe "for the shutdown timeout" do
      before do
        ARGV.replace(['-s', '9'])
      end

      it "should setup the matcher" do
        OptionParser.stub(:new).and_yield(opts).and_return(opts)
        opts.should_receive(:on).with("-s", "--shutdown_timeout SECONDS", "The number of seconds to wait for workers to finish [5]")

        Howler::Runner.new
      end

      it "should set the argument" do
        Howler::Runner.new.options[:shutdown_timeout].should == '9'
      end
    end


    it "should start the redis connection" do
      redis = mock(Redis, :with => nil)
      ARGV.replace(['-r', 'some/url:port'])

      Howler.should_receive(:_redis).ordered.with('some/url:port')
      Howler.should_receive(:redis).ordered.at_least(1).and_return(redis)

      Howler::Runner.new
    end

    it "should store the config in Howler::Config" do
      ARGV.replace(['-r', 'anything', '-c', '50'])

      Howler::Config.stub(:[]=)

      Howler::Config.should_receive(:[]=).with(:concurrency, '50')
      Howler::Config.should_receive(:[]=).with(:redis_url, 'anything')

      Howler::Runner.new
    end
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

    it "should sleep forever" do
      subject.should_receive(:sleep).with(no_args)

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

          it "should wait the specified number of seconds" do
            subject.should_receive(:sleep).with(6)

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
