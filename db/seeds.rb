# frozen_string_literal: true
require "faker"

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = Faker::Name.unique.name

  user.password = "password"
  user.password_confirmation = "password"

  user.role = :admin
end
