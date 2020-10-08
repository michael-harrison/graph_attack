require_relative '../base_mutation'

module Mutations
  module Auth
    class Logout < BaseMutation
      null true
      description 'Logout authenticated user'
      field :success, GraphQL::Types::Boolean, null: false

      def resolve
        {
          success: true
        }
      end
    end
  end
end