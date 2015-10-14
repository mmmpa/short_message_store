redis = Redis.new(
  host: ENV['REDIS_HOST'],
  port: ENV['REDIS_PORT']
)

Redis.current = case Rails.env.to_sym
                  when :development
                    Redis::Namespace.new(:dev, redis: redis)
                  when :test
                    Redis::Namespace.new(:test, redis: redis)
                  else
                    Redis::Namespace.new(:pro, redis: redis)
                end
