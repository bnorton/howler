require "spec_helper"

describe Sym::Logger do
  describe ".new" do
    it "should log to stdout" do
      ::Logger.should_receive(:new).with(STDOUT)

      Sym::Logger.new
    end
  end
end
