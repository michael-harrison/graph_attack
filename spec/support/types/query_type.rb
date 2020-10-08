require_relative 'base_object'

module Types
  class QueryType < Types::BaseObject
    field :inexpensive_field, GraphQL::Types::String, null: false

    def inexpensive_field
      'result'
    end

    field :expensive_field, GraphQL::Types::String, null: false do
      rate_limit threshold: 5, interval: 15
    end

    def expensive_field
      'result'
    end

    field :expensive_field2, GraphQL::Types::String, null: false do
      rate_limit threshold: 10, interval: 15
    end

    def expensive_field2
      'result'
    end
  end
end
