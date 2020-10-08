require_relative '../base_mutation'
require_relative '../../types/user_type'

module Mutations
  module Auth
    # == Mutations::Auth::Login
    # Mutation class allowing API user to authenticate gaining access to calls that require authentication
    #
    class Login < BaseMutation
      null true
      description 'Mutation for login'
      argument :email, String, required: true
      argument :password, String, required: true
      field :user, ::Types::UserType, null: true

      # @param [String] email
      # @param [String] password
      def resolve(email:, password:)
        @email = email
        @password = password

        {
          user: {
            id: 1,
            first_name: 'John',
            last_name: 'Citizen',
            email: 'john.citizen@example.com'
          }
        }
      end
    end
  end
end