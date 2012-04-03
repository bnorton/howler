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

      erb :queues
    end

    get "/queues/:queue_id" do
      @queue = Howler::Queue::new(params[:queue_id])
      @messages = @queue.processed_messages
      @pending = @queue.pending_messages
      @failed = @queue.failed_messages

      erb :queue
    end

    get "/notifications" do
      @notifications = Howler::Queue.notifications

      erb :notifications
    end

    helpers do
      def process_args(args)
        args.to_s.gsub(/^\[|\]$/, '')
      end
    end
  end
end
