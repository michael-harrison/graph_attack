# frozen_string_literal: true

require_relative 'types/query_type'
require_relative 'types/mutation_type'

class DefaultSchema < GraphQL::Schema
  query_analyzer GraphAttack::RateLimiter.new
  query Types::QueryType
  mutation Types::MutationType
end
