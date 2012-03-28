require "spec_helper"

describe "web" do
  include Capybara::DSL
  let!(:queue) { Sym::Queue.new }
  let(:message) do
    Sym::Message.new(
      'class' => 'Array',
      'method' => :length,
      'args' => [2345]
    )
  end

  describe "#root" do
    it "when viewing the navigation bar" do
      visit "/"

      within "#navigation" do
        page.should have_content("Home")
        page.should have_content("Queues")
        page.should have_content("Messages")
        page.should have_content("Workers")
        page.should have_content("Statistics")
      end
    end

    it "when navigating to Queues#index" do
      visit "/"
      click_link "Queues"

      current_path.should == "/queues"
    end

    it "when navigating to Messages#index" do
      visit "/"
      click_link "Messages"

      current_path.should == "/messages"
    end

    it "when navigating to Workers#index" do
      visit "/"
      click_link "Workers"

      current_path.should == "/workers"
    end

    it "when navigating to Statistics#index" do
      visit "/"
      click_link "Statistics"

      current_path.should == "/statistics"
    end
  end

  describe "Queues#index" do
    it "when navigating to Queues#show" do
      visit "/queues"

      within "#queue_#{queue.id}" do
        click_link "More..."
      end

      current_path.should == "/queues/#{queue.id}"

      within "##{queue.id}" do
        page.should have_content(queue.id)
      end
    end

    it "when viewing queue statistics" do
      6.times { queue.statistics { lambda {}}}
      4.times { queue.statistics { raise "failed" }}

      visit "/queues"

      within "#queue_#{queue.id}" do
        page.should have_content(queue.id)
        page.should have_content(queue.created_at.to_s)
        page.should have_content("6")

        within ".error" do
          page.should have_content("4")
        end
      end
    end
  end

  describe "Messages#index" do
    before do
      Benchmark.stub(:measure).and_return("1.1 1.3 1.5 ( 1.7)", "2.1 2.3 2.5 ( 2.7)")
      Array.stub(:length).with(2345).and_raise(Sym::Message::Failed)
    end

    it "viewing the failed message metadata" do
      queue.immediate(message)

      visit "/messages"

      within "#failed_messages" do
        within ".table tr" do
          ["Class", "Method", "Args", "Created At", "Failed At", "Cause", "System Runtime", "Real Runtime"].each do |value|
            page.should have_content(value)
          end
        end

        #within ".table tbody" do
        #  %w(Array length 2345 Sym::Message::Failed 1.5 1.7).each do |value|
        #    page.should have_content(value)
        #  end
        #end
      end
    end
  end

  describe "Queues#show" do
    before do
      Benchmark.stub(:measure).and_return("1.1 1.3 1.5 ( 1.7)", "2.1 2.3 2.5 ( 2.7)")
      Timecop.travel(DateTime.now)
      @time = Time.now.to_f

      [[Hash, :keys, [1234]], [Array, :length, [2345]]].each do |(klass, method, args)|
        queue.statistics(klass, method, args, @time) { lambda {}}
      end

      [[Thread, :current, [3456]]].each do |(klass, method, args)|
        Sym::Manager.push(klass, method, args)
      end
    end

    it "when viewing processed messages" do
      visit "/queues/#{queue.id}"

      within "#processed_messages" do
        within ".table_title" do
          page.should have_content("Processed Messages")
        end

        within ".table tr" do
          ["Class", "Method", "Args", "Created At", "System Runtime", "Real Runtime", "Status"].each do |value|
            page.should have_content(value)
          end
        end

        within ".table tbody" do
          page.should have_content(Sym::Util.at(@time))

          %w(Array length 1234 1.5 1.7 success).each do |value|
            page.should have_content(value)
          end

          %w(Hash keys 2345 2.5 2.7 success).each do |value|
            page.should have_content(value)
          end
        end
      end
    end

    it "when viewing pending messages" do
      visit "/queues/#{queue.id}"

      within "#pending_messages" do
        within ".table_title" do
          page.should have_content("Pending Messages")
        end

        within ".table tr" do
          ["Class", "Method", "Args", "Created At", "Status"].each do |value|
            page.should have_content(value)
          end
        end

        within ".table tbody" do
          page.should have_content(Sym::Util.at(@time))

          %w(Thread current 3456 pending).each do |value|
            page.should have_content(value)
          end
        end
      end
    end

    it "viewing the failed message metadata" do
      Array.stub(:length).with(2345).and_raise(Sym::Message::Failed)
      queue.immediate(message)

      visit "/messages"

      within "#failed_messages" do
        within ".table_title" do
          page.should have_content("Failed Messages")
        end

        within ".table tr" do
          ["Class", "Method", "Args", "Created At", "Failed At", "Cause", "System Runtime", "Real Runtime"].each do |value|
            page.should have_content(value)
          end
        end

        #within ".table tbody" do
        #  %w(Array length 2345 Sym::Message::Failed 1.5 1.7).each do |value|
        #    page.should have_content(value)
        #  end
        #end
      end
    end
  end
end
