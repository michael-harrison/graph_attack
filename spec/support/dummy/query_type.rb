module Dummy
  QueryType = GraphQL::ObjectType.define do
    name 'Query'

    field :inexpensiveField do
      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end

    field :expensiveField do
      rate_limit threshold: 5, interval: 15

      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end

    field :expensiveField2 do
      rate_limit threshold: 10, interval: 15

      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end
  end
end