# frozen_string_literal: true
require "faker"

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = Faker::Name.unique.name

  user.password = "password"
  user.password_confirmation = "password"

  user.role = :admin
end

Agent.find_or_create_by!(email: "agent@example.com") do |agent|
  agent.name = "Jane Agent"

  agent.phone = "0794876987"
end

Applicant.find_or_create_by!(email: "applicant@example.com") do |applicant|
  applicant.name = "Jason Agent"

  applicant.phone = "0794111111"
end
