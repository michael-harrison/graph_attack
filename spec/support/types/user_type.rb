require_relative 'base_object'

module Types
  class UserType < Types::BaseObject
    description 'User of the system'
    field :id, ID, null: false
    field :first_name, String, null: false
    field :last_name, String, null: false
    field :email, String, null: false
  end
end
