module Resque
  module Views
    class Working < Layout
      def single_worker?
        id = params[:id]
        if id && (worker = Resque::Worker.find(id)) && worker.job
          worker
        end
      end

      def all_workers?
        !params[:id]
      end

      def working
        Resque.working.
          sort_by { |w| w.job['run_at'] ? w.job['run_at'] : '' }.
          reject { |w| w.idle? }.
          map { |worker| { :worker => worker } }
      end

      def none_working?
        working.empty?
      end

      def no_job
        !self[:job]
      end

      def workers_working
        Resque.working.size
      end

      def workers_total
        Resque.workers.size
      end

      def state_icon
        u(self[:worker].state) + '.png'
      end

      def worker_host
        worker_parts[0]
      end

      def worker_pid
        worker_parts[1]
      end

      def worker_queues
        worker_parts[2..-1]
      end

      def worker_parts
        self[:worker].to_s.split(':')
      end

      def queue
        self[:queue]
      end

      def queue_url
        u "/queues/#{queue}"
      end

      def worker_url
        u "/workers/#{self[:worker]}"
      end

      def working_url
        u "/working/#{self[:worker]}"
      end
    end
  end
end

