# frozen_string_literal: true

require_relative 'types/query_type'

CUSTOM_REDIS_CLIENT = Redis.new

class CustomSchema < GraphQL::Schema
  query_analyzer GraphAttack::RateLimiter.new(
    redis_client: CUSTOM_REDIS_CLIENT,
    )
  query Types::QueryType
end
