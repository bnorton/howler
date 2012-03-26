require "spec_helper"

describe "web" do
  include Capybara::DSL

  let!(:queue) { Sym::Queue.new() }

  describe "#index" do
    it "should have a navigation bar" do
      visit "/"

      within "#navigation" do
        page.should have_content("Sym")
        page.should have_content("Home")
        page.should have_content("Queues")
      end
    end

    it "should navigate to Queues#index" do
      10.times { queue.statistics { lambda {}}}
      12.times { queue.statistics { raise "failed" }}

      visit "/"
      click_link "Queues"

      current_path.should == "/queues"

      within "#queue_#{queue.id}" do
        page.should have_content(queue.id)
        page.should have_content(queue.created_at.to_s)
        page.should have_content(queue.success.to_s)
        page.should have_content(queue.error.to_s)
      end
    end

    it "should navigate to Queues#show" do
      visit "/queues"

      within "#queue_#{queue.id}" do
        click_link "More..."
      end

      current_path.should == "/queues/#{queue.id}"

      within "##{queue.id}" do
        page.should have_content(queue.id)
      end
    end
  end

  describe "#show" do
    before do
      Timecop.travel(DateTime.now)
      @time = Time.now.to_f

      Benchmark.stub(:measure).and_return("1.1 1.3 1.5 ( 1.7)", "2.1 2.3 2.5 ( 2.7)")

      [[Hash, :keys, [1234]], [Array, :length, [2345]]].each do |(klass, method, args)|
        queue.statistics(klass, method, args, @time) { lambda {}}
      end

      [[Thread, :current, [3456]]].each do |(klass, method, args)|
        Sym::Manager.push(klass, method, args)
      end
    end

    it "when viewing the message and metadata for processed messages" do
      visit "/queues/#{queue.id}"

      within "#processed_messages .table tr" do
        ["Class", "Method", "Args", "Created At", "System Runtime", "Real Runtime", "Status"].each do |value|
          page.should have_content(value)
        end
      end
    end

    it "when viewing Queue#show processed messages" do
      visit "/queues/#{queue.id}"

      within "#processed_messages .table tbody" do
        page.should have_content(Sym::Util.at(@time))

        %w(Array length 1234 1.5 1.7 success).each do |value|
          page.should have_content(value)
        end

        %w(Hash keys 2345 2.5 2.7 success).each do |value|
          page.should have_content(value)
        end
      end
    end

    it "when viewing the message and metadata for pending messages" do
      visit "/queues/#{queue.id}"

      within "#pending_messages .table tr" do
        ["Class", "Method", "Args", "Created At", "Status"].each do |value|
          page.should have_content(value)
        end
      end
    end

    it "when viewing Queue#show pending messages" do
      visit "/queues/#{queue.id}"

      within "#pending_messages .table tbody" do
        page.should have_content(Sym::Util.at(@time))

        %w(Thread current 3456 pending).each do |value|
          page.should have_content(value)
        end
      end
    end
  end
end
