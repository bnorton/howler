require "spec_helper"

describe Howler::Config do
  it "should have an attribute white-list" do
    Howler::Config::WHITELIST.should == %w(concurrency)
  end

  describe ".[]" do
    before do
      Howler.redis.with {|redis| redis.hset("howler:config", "concurrency", "10") }
    end

    it "should configure options" do
      Howler::Config[:concurrency].should == "10"
    end
  end

  describe ".[]=" do
    before do
      Howler::Config[:message] = '{"key": 3}'
    end

    it "should configure options" do
      Howler.redis.with {|redis| redis.hget("howler:config", "message") }.should == '{"key": 3}'
    end

    describe "when the value is nil" do
      it "should remove the key" do
        Howler.redis.with {|redis| redis.hexists("howler:config", "message") }.should == true

        Howler::Config[:message] = nil

        Howler.redis.with {|redis| redis.hexists("howler:config", "message") }.should == false
      end
    end
  end

  describe ".flush" do
    before do
      Howler::Config[:concurrency] = 10

      [:message, :flag, :boolean].each do |key|
        Howler::Config[key] = "unimportant value"
      end
    end
    it "should clear all non-whitelisted config" do
      Howler::Config.flush

      [:message, :flag, :boolean].each do |key|
        Howler.redis.with {|redis| redis.hget("howler:config", key.to_s) }.should be_nil
      end

      Howler::Config[:concurrency].to_i.should == 10
    end
  end
end
