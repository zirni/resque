module Resque
  module Views
    class Stats < Layout
      def subtabs
        %w( resque redis keys )
      end

      def redis_server
        Resque.redis.server
      end

      def key_page?
        params[:id] == "key"
      end

      def key_string_or_sets
        Resque.redis.type(params[:key]) == "string" ? :key_string : :key_sets
      end

      def keys_page?
        params[:id] == "keys"
      end

      def keys
        Resque.keys.sort.map do |key|
          hash = {}
          hash[:name] = key
          hash[:href] = u("/stats/keys/#{key}")
          hash[:type] = resque.redis.type(key)
          hash[:size] = redis_get_size(key)
          hash
        end
      end

      def resque_page?
        ResqueInfo.new if params[:id] == "resque"
      end

      def redis_page?
        RedisInfo.new if params[:id] == "redis"
      end

      class ResqueInfo
        def stats
          Resque.info.to_a.sort_by { |i| i[0].to_s }.map do |key, value|
            { :key => key, :value => value }
          end
        end
      end

      class RedisInfo
        def stats
          Resque.redis.info.to_a.sort_by { |i| i[0].to_s }.map do |key, value|
            { :key => key, :value => value }
          end
        end
      end
    end
  end
end
