require_relative 'base_object'

module Types
  class QueryType < Types::BaseObject
    field :inexpensive_field, GraphQL::Types::String, null: false, description: 'A field that is never expensive to include in a query'

    def inexpensive_field
      'result'
    end

    field :expensive_field, GraphQL::Types::String, null: false do
      description 'A field that is always expensive to include in a query'
      rate_limit threshold: 5, interval: 15
    end

    def expensive_field
      'result'
    end

    field :sometimes_expensive_field, GraphQL::Types::String, null: false, description: 'A field that is sometimes expensive to include in a query'

    def sometimes_expensive_field
      status = GraphAttack::RateLimiter.new.manual_count_increment(
        ip: context[:ip],
        name: 'sometimesExpensiveField',
        threshold: 5,
        interval: 15
      )

      if status == :exceeded
        raise GraphQL::ExecutionError, 'This field has been expensive to run too many times'
      else
        'result'
      end
    end

    field :expensive_field2, GraphQL::Types::String, null: false do
      rate_limit threshold: 10, interval: 15
    end

    def expensive_field2
      'result'
    end
  end
end
