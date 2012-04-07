require "spec_helper"

describe Howler do
  describe ".next" do
    before do
      Howler.unstub(:next)
    end

    it "should return a number" do
      Howler.next(:id).class.should == Fixnum
    end

    it "should be increase by one" do
      before = Howler.next(:id)

      (before + 1).should == Howler.next(:id)
    end

    describe "for multiple keys" do
      before do
        Howler.next(:foo)
      end

      it "should have different counts" do
        [
          Howler.next(:id),
          Howler.next(:id),
          Howler.next(:foo),
          Howler.next(:foo)
        ].should == [1, 2, 2, 3]
      end
    end
  end

  describe ".args" do
    it "should remove square brackets" do
      Howler.args([]).should == ""
    end

    it "should remove only leading and trailing brackets" do
      Howler.args([10, {'akey' => 'avalue'}]).should == '10, {"akey"=>"avalue"}'
    end
  end

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
