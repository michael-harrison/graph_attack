require_relative 'query_type'

module Dummy
  Schema = GraphQL::Schema.define do
    query QueryType
    query_analyzer GraphAttack::RateLimiter.new
  end
end