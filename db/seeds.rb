# frozen_string_literal: true

require "faker"

lambeth = LocalAuthority.find_or_create_by!(
  name: "Lambeth Council",
  subdomain: "lambeth",
  signatory_name: "Christina Thompson",
  signatory_job_title: "Director of Finance & Property",
  enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@lambeth.gov.uk"
)
southwark = LocalAuthority.find_or_create_by!(
  name: "Southwark Council",
  subdomain: "southwark",
  signatory_name: "Stephen Platts",
  signatory_job_title: "Director of Planning and Growth",
  enquiries_paragraph: "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@southwark.gov.uk"
)

buckinghamshire = LocalAuthority.find_or_create_by!(
  name: "Buckinghamshire",
  subdomain: "buckinghamshire",
  signatory_name: "Steve Bambick",
  signatory_job_title: "Director of Planning",
  enquiries_paragraph: "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF",
  email_address: "planning@buckinghamshire.gov.uk"
)

ApiUser.find_or_create_by!(name: "api_user", token: (ENV["API_TOKEN"] || "123"))

admin_roles = %i[assessor reviewer]
local_authorities = [southwark, lambeth, buckinghamshire]

local_authorities.each do |authority|
  authority.readonly!

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{authority.subdomain}_#{admin_role}@example.com") do |user|
      first_name = Faker::Name.unique.first_name
      last_name = Faker::Name.unique.last_name
      user.name = "#{first_name} #{last_name}"
      user.local_authority = authority
      if Rails.env.development?
        user.password = user.password_confirmation = "password"
      else
        user.password = user.password_confirmation = SecureRandom.uuid
        user.encrypted_password =
          "$2a$11$uvtPXUB2CmO8WEYm7ajHf.XhZtBsclT/sT45ijLMIELShaZvceW5."
      end
      user.role = admin_role
    end
  end
end
