# frozen_string_literal: true
require "faker"

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "#{Faker::Name.unique.first_name} #{Faker::Name.unique.last_name}"

  if Rails.env.development?
    user.password = user.password_confirmation = "password"
  else
    user.password = user.password_confirmation = SecureRandom.uuid
    user.encrypted_password =
      "$2a$11$.ymnkBkdw1/qPlKPWXa5WujF/Ry/R0nUjZVvo4lEvwc3HL3drZ12W"
  end

  user.role = :admin
end

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
