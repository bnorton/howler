require "spec_helper"

describe Sym::Runner do
  describe "#run" do
    let!(:manager) { Sym::Manager.new }

    before do
      Sym::Manager.stub(:new).and_return(manager)
      manager.stub(:run!)
    end

    it "should create a manager" do
      Sym::Manager.should_receive(:new)

      subject.run
    end

    it "should run the manager" do
      manager.should_receive(:run!)

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
