require 'rubygems'
require 'bundler/setup'

require 'timecop'
require 'benchmark'
require 'capybara'
require 'capybara/dsl'

require 'multi_json'
require 'logger'

require 'howler'
require 'howler/async'
require 'howler/web'

# Comment this out if you need to run request specs in a browser
Capybara.default_driver = :selenium

Capybara.app = Howler::Web

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:each) do
    Howler.send(:_redis).flushall
  end
end
class Change
  attr_accessor :queue
  def length_by(amount)
    redis = Howler.send(:_redis)

    [:llen, :zcard].each do |method|
      begin
        before = redis.send(method, queue)
        yield
        return (redis.send(method, queue) - before).should == amount
      rescue RuntimeError
      end
    end
  end
end
def should_change(queue)
  change = Change.new
  change.queue = queue
  change
end

module FixnumMethods
  def minutes
    self * 60
  end

  def hours
    self * 60.minutes
  end

  def days
    self * 24.hours
  end

  alias :minute :minutes
  alias :hour :hours
  alias :day :days
end

Fixnum.send(:include, FixnumMethods)
