require_relative ''

require 'sinatra/base'
require 'erb'

module Sym
  class Web < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :static, true
    set :views, "#{dir}/web/views"
    set :public_folder, "#{dir}/web/public"

    get "/" do
      erb :index
    end

    get "/queues" do
      @queues = (Sym.redis.with {|redis| redis.smembers(Sym::Queue::INDEX) }).collect do |queue|
        Sym::Queue::new(queue)
      end

      erb :queues_index
    end

    get "/queues/:queue_id" do
      @queue = Sym::Queue::new(params[:queue_id])
      @messages = @queue.processed_messages
      @pending = @queue.pending_messages

      erb :queue_show
    end

    get "/messages" do
      erb :messages_index
    end

    helpers do
    end
  end
end
