require 'rubygems'
require 'bundler/setup'

require 'timecop'
require 'benchmark'
require 'capybara'
require 'capybara/dsl'

require 'multi_json'

require 'sym'
require 'sym/async'
require 'sym/web'

# Comment this out if you need to run request specs in a browser
Capybara.default_driver = :selenium

Capybara.app = Sym::Web

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:each) do
    Sym.send(:_redis).flushall
  end
end
class Change
  attr_accessor :queue
  def length_by(amount)
    before = Sym.send(:_redis).llen(queue)
    yield
    (Sym.send(:_redis).llen(queue) - before).should == amount
  end
end
def should_change(queue)
  change = Change.new
  change.queue = queue
  change
end