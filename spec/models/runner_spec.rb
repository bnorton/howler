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
        manager.unstub(:run!)
        manager.stub(:sleep).and_raise(Interrupt)
      end

      it "should trap the interrupt" do
        expect {
          subject.run
        }.not_to raise_error
      end
    end
  end
end
