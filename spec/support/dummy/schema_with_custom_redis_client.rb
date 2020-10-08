require_relative 'query_type'

module Dummy
  CUSTOM_REDIS_CLIENT = Redis.new

  SchemaWithCustomRedisClient = GraphQL::Schema.define do
    query QueryType
    query_analyzer GraphAttack::RateLimiter.new(
      redis_client: CUSTOM_REDIS_CLIENT,
      )
  end
end