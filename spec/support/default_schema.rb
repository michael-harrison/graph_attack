require_relative 'types/query_type'

class DefaultSchema < GraphQL::Schema
  query_analyzer GraphAttack::RateLimiter.new
  query Types::QueryType
end
