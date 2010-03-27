require 'erb'

require 'sinatra/base'
require 'mustache/sinatra'

require 'resque'
require 'resque/version'

require 'resque/server/helpers'
require 'resque/server/views/layout'

module Resque
  class Server < Sinatra::Base
    register Mustache::Sinatra
    helpers Helpers

    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    set :mustache, {
      :namespace => Resque,
      :templates => "#{dir}/server/templates",
      :views     => "#{dir}/server/views"
    }

    def show(page, layout = true)
      templates = settings.mustache[:templates]

      if File.exists? "#{templates}/#{page}.mustache"
        mustache page.to_sym
      else
        erb page.to_sym, {:layout => layout}, :resque => Resque
      end
    rescue Errno::ECONNREFUSED
      erb :error, { :layout => false },
        :error => "Can't connect to Redis! (#{Resque.redis.server})"
    end

    # to make things easier on ourselves
    get "/?" do
      redirect url(:overview)
    end

    %w( overview queues working workers key ).each do |page|
      get "/#{page}" do
        show page
      end

      get "/#{page}/:id" do
        show page
      end
    end

    post "/queues/:id/remove" do
      Resque.remove_queue(params[:id])
      redirect u('queues')
    end

    %w( overview workers ).each do |page|
      get "/#{page}.poll" do
        content_type "text/plain"
        @polling = true
        show(page.to_sym, false).gsub(/\s{1,}/, ' ')
      end
    end

    get "/failed" do
      if Resque::Failure.url
        redirect Resque::Failure.url
      else
        show :failed
      end
    end

    post "/failed/clear" do
      Resque::Failure.clear
      redirect u('failed')
    end

    get "/failed/requeue/:index" do
      Resque::Failure.requeue(params[:index])
      redirect u('failed')
    end

    get "/stats" do
      redirect url("/stats/resque")
    end

    get "/stats/:id" do
      show :stats
    end

    get "/stats/keys/:key" do
      show :stats
    end

    get "/stats.txt" do
      info = Resque.info

      stats = []
      stats << "resque.pending=#{info[:pending]}"
      stats << "resque.processed+=#{info[:processed]}"
      stats << "resque.failed+=#{info[:failed]}"
      stats << "resque.workers=#{info[:workers]}"
      stats << "resque.working=#{info[:working]}"

      Resque.queues.each do |queue|
        stats << "queues.#{queue}=#{Resque.size(queue)}"
      end

      content_type 'text/plain'
      stats.join "\n"
    end

    def resque
      Resque
    end

    def self.tabs
      @tabs ||= ["Overview", "Working", "Failed", "Queues", "Workers", "Stats"]
    end
  end
end
