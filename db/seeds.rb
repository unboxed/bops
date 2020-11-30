# frozen_string_literal: true
require "faker"

Agent.find_or_create_by!(email: "agent@example.com") do |agent|
  agent.first_name = Faker::Name.unique.first_name,
  agent.last_name = Faker::Name.unique.last_name,
  agent.phone = Faker::Base.numerify("+44 7### ######")
end

Applicant.find_or_create_by!(email: "bops-team@unboxedconsulting.com") do |applicant|
  applicant.first_name = Faker::Name.unique.first_name,
  applicant.last_name = Faker::Name.unique.last_name,
  applicant.phone = Faker::Base.numerify("+44 7### ######")
  applicant.residence_status = true
end
