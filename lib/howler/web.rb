require_relative ''

require 'sinatra/base'
require 'erb'

module Howler
  class Web < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :static, true
    set :views, "#{dir}/web/views"
    set :public_folder, "#{dir}/web/public"

    get "/" do
      erb :index
    end

    get "/queues" do
      @queues = (Howler.redis.with {|redis| redis.smembers(Howler::Queue::INDEX) }).collect do |queue|
        Howler::Queue::new(queue)
      end

      erb :queues_index
    end

    get "/queues/:queue_id" do
      @queue = Howler::Queue::new(params[:queue_id])
      @messages = @queue.processed_messages
      @pending = @queue.pending_messages
      @failed = @queue.failed_messages

      erb :queue_show
    end

    helpers do
    end
  end
end
