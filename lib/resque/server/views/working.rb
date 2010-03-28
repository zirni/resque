module Resque
  module Views
    class Working < Layout
      # If we're only looking at a single worker, return it as the
      # context.
      def single_worker?
        id = params[:id]
        if id && (worker = Resque::Worker.find(id)) && worker.job
          worker
        end
      end

      # If we're not looking at a single worker, we're looking at all
      # fo them.
      def all_workers?
        !params[:id]
      end

      # A sorted array of workers currently working.
      def working
        Resque.working.
          sort_by { |w| w.job['run_at'] ? w.job['run_at'] : '' }.
          reject { |w| w.idle? }
      end

      # Is no one working?
      def none_working?
        working.empty?
      end

      # Does this context have a job?
      def no_job
        !self[:job]
      end

      # The number of workers currently working.
      def workers_working
        Resque.working.size
      end

      # The number of workers total.
      def workers_total
        Resque.workers.size
      end

      # A full URL to the icon representing a worker's state.
      def state_icon
        u(self[:state]) + '.png'
      end

      # Host where the current worker lives.
      def worker_host
        worker_parts[0]
      end

      # PID of the current worker.
      def worker_pid
        worker_parts[1]
      end

      # Queues the current worker is concerned with.
      def worker_queues
        worker_parts[2..-1]
      end

      # The current worker's name split into three parts:
      # [ host, pid, queues ]
      def worker_parts
        self[:to_s].split(':')
      end

      # TODO: Mustache method_missing this guy
      def queue
        self[:queue]
      end

      # URL of the current job's queue
      def queue_url
        u "/queues/#{queue}"
      end

      # Worker URL of the current worker
      def worker_url
        u "/workers/#{self[:to_s]}"
      end

      # Working URL of the current working
      def working_url
        u "/working/#{self[:to_s]}"
      end
    end
  end
end
