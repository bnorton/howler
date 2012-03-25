require "spec_helper"

describe Sym::Message do
  subject do
    Sym::Message.new(
      "class" => "Array",
      "method" => "length",
      "args" => [1234]
    )
  end

  describe ".new" do
    describe "requirements" do
      it "should require a class" do
        expect {
          Sym::Message.new("method" => 'hey')
        }.to raise_error(NoMethodError)
      end

      it "should require a valid class" do
        expect {
          Sym::Message.new("class" => 'a', "method" => 'hey')
        }.to raise_error(NameError)
      end

      it "should require a method" do
        expect {
          Sym::Message.new("class" => 'Array')
        }.to raise_error(ArgumentError, "A message requires a method")
      end
    end
  end

  describe "#klass" do
    it "should return the class literal" do
      subject.klass.should == Array
    end
  end

  describe "#method" do
    it "should return the synbolized method" do
      subject.method.should == :length
    end
  end

  describe "#args" do
    it "should return the arguments" do
      subject.args.should == [1234]
    end
  end
end
