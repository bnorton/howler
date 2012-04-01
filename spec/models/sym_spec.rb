require "spec_helper"

describe Howler do
  describe ".redis" do
    let(:pool) { mock("ConnectionPool2") }

    xit "should be a ConnectionPool" do
      ConnectionPool.should_receive(:new).with(:timeout => 1, :size => 5)

      Howler.redis
    end

    xit "should cache the ConnectionPool" do
      ConnectionPool.stub(:new).and_return(pool, mock("ConnPool"))

      Howler.redis.should == Howler.redis
    end

    xit "should be an key-value store" do
      Howler.redis.stub(:with).and_yield(Howler.send(:_redis))

      Howler.redis.with do |redis|
        redis.set("key", "value")
        redis.get("key").should == "value"
      end
    end
  end
end
