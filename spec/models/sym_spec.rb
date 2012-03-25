require "spec_helper"

describe Sym do
  describe ".redis" do
    let(:pool) { mock("ConnectionPool2") }

    xit "should be a ConnectionPool" do
      ConnectionPool.should_receive(:new).with(:timeout => 1, :size => 5)

      Sym.redis
    end

    xit "should cache the ConnectionPool" do
      ConnectionPool.stub(:new).and_return(pool, mock("ConnPool"))

      Sym.redis.should == Sym.redis
    end

    xit "should be an key-value store" do
      Sym.redis.stub(:with).and_yield(Sym.send(:_redis))

      Sym.redis.with do |redis|
        redis.set("key", "value")
        redis.get("key").should == "value"
      end
    end
  end
end
