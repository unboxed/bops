# frozen_string_literal: true
require "faker"

lambeth = LocalAuthority.find_or_create_by!(
  name: "Lambeth Council",
  subdomain: "lambeth",
  signatory_name: "Christina Thompson",
  signatory_job_title: "Director of Finance & Property",
  enquiries_paragraph: "Postal address: Planning London Borough of Lambeth PO Box 734 Winchester SO23 5DG",
  email_address: "planning@lambeth.gov.uk"
)

southwark = LocalAuthority.find_or_create_by!(
  name: "Southwark Council",
  subdomain: "southwark",
  signatory_name: "Simon Bevan",
  signatory_job_title: "Director of Planning",
  enquiries_paragraph: "Postal address: Planning London Borough of Southwark PO Box 734 Winchester SO23 5DG",
  email_address: "planning@southwark.gov.uk"
)

bucks = LocalAuthority.find_or_create_by!(
  name: "Buckinghamshire",
  subdomain: "bucks",
  signatory_name: "Steve Bambick",
  signatory_job_title: "Director of Planning",
  enquiries_paragraph: "Postal address: Planning Buckinghamshire Council, The Gateway, Gatehouse Rd, Aylesbury HP19 8FF",
  email_address: "planning@buckinghamshire.gov.uk"
)

User.find_or_create_by!(email: "southwark_admin@example.com") do |user|
  user.name = "#{Faker::Name.unique.first_name} #{Faker::Name.unique.last_name}"
  user.local_authority = southwark

  if Rails.env.development?
    user.password = user.password_confirmation = "password"
  else
    user.password = user.password_confirmation = SecureRandom.uuid
    user.encrypted_password =
      "$2a$11$.ymnkBkdw1/qPlKPWXa5WujF/Ry/R0nUjZVvo4lEvwc3HL3drZ12W"
  end

  user.role = :admin
end
