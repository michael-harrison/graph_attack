require_relative 'base_object'
require_relative '../mutations/auth/login'
require_relative '../mutations/auth/limited_login'
require_relative '../mutations/auth/logout'

module Types
  class MutationType < Types::BaseObject
    field :limited_login, mutation: ::Mutations::Auth::LimitedLogin
    field :login, mutation: ::Mutations::Auth::Login do
      rate_limit threshold: 5, interval: 15
    end

    field :logout, mutation: ::Mutations::Auth::Logout
  end
end
