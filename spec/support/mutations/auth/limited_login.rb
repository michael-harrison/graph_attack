require_relative '../base_mutation'
require_relative '../../types/user_type'

module Mutations
  module Auth
    # == Mutations::Auth::LimitedLogin
    # Mutation class allowing API user to authenticate gaining access to calls that require authentication with a limit
    # on the number of failed passwords for a specific IP address
    #
    class LimitedLogin < BaseMutation
      null true
      description 'Mutation for login'
      argument :email, String, required: true
      argument :password, String, required: true
      field :user, ::Types::UserType, null: true
      field :success, Boolean, null: false

      # @param [String] email
      # @param [String] password
      def resolve(email:, password:)
        @email = email
        @password = password

        successful = password == 'something secret'

        if successful
          user = {
            id: 1,
            first_name: 'John',
            last_name: 'Citizen',
            email: 'john.citizen@example.com'
          }
        else
          status = GraphAttack::RateLimiter.new.manual_count_increment(
            ip: context[:ip],
            name: 'loginFailure',
            threshold: 5,
            interval: 15
          )

          raise GraphQL::ExecutionError, 'This field has been expensive to run too many times' if status == :exceeded
        end

        {
          success: successful,
          user: user
        }
      end
    end
  end
end