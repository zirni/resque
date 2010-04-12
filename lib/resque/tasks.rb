# require 'resque/tasks'
# will give you the resque tasks

def initialization_tasks
  tasks = []
  tasks << :environment if Rake::Task.task_defined?(:environment)
  tasks << :setup
  tasks
end

namespace :resque do
  task :setup

  desc "Start a Resque worker"
  task :work => initialization_tasks do
    require 'resque'

    worker = nil
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

    begin
      worker = Resque::Worker.new(*queues)
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Resque::NoQueueError
      abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    puts "*** Starting worker #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple Resque workers. Should only be used in dev mode."
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake resque:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end
