require "spec_helper"

describe Sym::Async do
  class Worker
    async :fetch, :parse

    def fetch
    end

    def self.parse
    end
  end

  describe "#async" do
    describe "for an instance method" do
      it "should define 'async_' prefixed class methods" do
        Worker.new.respond_to?(:fetch).should == true

        Worker.respond_to?(:async_fetch).should == true
      end
    end

    describe "for a class method" do
      it "should define 'async_' prefixed class methods" do
        Worker.respond_to?(:parse).should == true

        Worker.respond_to?(:async_parse).should == true
      end
    end

    describe "async_ methods" do
      it "should accept 0 arguments" do
        expect {
          Worker.async_fetch
        }.not_to raise_error(ArgumentError)
      end

      it "should accept 1 argument" do
        expect {
          Worker.async_fetch(1)
        }.not_to raise_error(ArgumentError)
      end

      it "should accept many arguments" do
        expect {
          Worker.async_fetch(1,2,3)
        }.not_to raise_error(ArgumentError)
      end
    end

    describe "storing the message" do
     describe "when there are no arguments" do
       it "should register the message" do
         Sym::Manager.should_receive(:push).with(Worker, :fetch, [])

         Worker.async_fetch
       end
     end

      describe "when there are arguments" do
        it "should register the message" do
          Sym::Manager.should_receive(:push).with(Worker, :fetch, [1, 2, {:key => 'value'}])

          Worker.async_fetch(1, 2, :key => 'value')
        end
      end
    end
  end
end
