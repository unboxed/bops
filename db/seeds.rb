# frozen_string_literal: true

require "faker"

lambeth = LocalAuthority.find_or_create_by!(
  council_code: "LBH",
  subdomain: "lambeth",
  signatory_name: "Christina Thompson",
  signatory_job_title: "Director of Finance & Property",
  enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@lambeth.gov.uk",
  feedback_email: "digitalplanning@lambeth.gov.uk"
)
southwark = LocalAuthority.find_or_create_by!(
  council_code: "SWK",
  subdomain: "southwark",
  signatory_name: "Stephen Platts",
  signatory_job_title: "Director of Planning and Growth",
  enquiries_paragraph: "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@southwark.gov.uk",
  feedback_email: "digital.projects@southwark.gov.uk"
)

buckinghamshire = LocalAuthority.find_or_create_by!(
  council_code: "BUC",
  subdomain: "buckinghamshire",
  signatory_name: "Steve Bambick",
  signatory_job_title: "Director of Planning",
  enquiries_paragraph: "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF",
  email_address: "planning@buckinghamshire.gov.uk",
  feedback_email: "planning.digital@buckinghamshire.gov.uk"
)

ApiUser.find_or_create_by!(name: "api_user", token: (ENV["API_TOKEN"] || "123"))

admin_roles = %i[assessor reviewer administrator]
local_authorities = [southwark, lambeth, buckinghamshire]

local_authorities.each do |authority|
  authority.readonly!

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{authority.subdomain}_#{admin_role}@example.com") do |user|
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      user.name = "#{first_name} #{last_name}"
      user.local_authority = authority
      if Rails.env.development?
        user.password = user.password_confirmation = "nw29nfsijrP!P392"
      else
        user.password = user.password_confirmation = PasswordGenerator.call
        user.encrypted_password =
          "$2a$11$uvtPXUB2CmO8WEYm7ajHf.XhZtBsclT/sT45ijLMIELShaZvceW5."
      end
      user.role = admin_role
      user.otp_required_for_login = false
    end
  end
end

application_types = [
  { name: "lawfulness_certificate" },
  { name: "prior_approval", part: 1, section: "A" },
  { name: "planning_permission" }
]

application_types.each do |attrs|
  ApplicationType.find_or_create_by!(attrs)
end

constraints_list = {
  flooding: [
    "Flood zone",
    "Flood zone 1",
    "Flood zone 2",
    "Flood zone 3"
  ],
  military_and_defence: [
    "Explosives & ordnance storage",
    "Safeguarded land"
  ],
  ecology: [
    "Special Area of Conservation (SAC)",
    "Site of Special Scientific Interest (SSSI)",
    "Ancient Semi-Natural Woodland (ASNW)",
    "Local Wildlife / Biological notification site",
    "Priority habitat"
  ],
  heritage_and_conservation: [
    "Listed Building",
    "Conservation Area",
    "Area of Outstanding Natural Beauty",
    "National Park",
    "World Heritage Site",
    "Broads"
  ],
  general_policy: [
    "Article 4 area",
    "Green belt"
  ],
  tree: [
    "Tree Preservation Order"
  ],
  other: [
    "Safety hazard area",
    "Within 3km of the perimeter of an aerodrome"
  ]
}

constraints_list.each do |category, names|
  names.each do |name|
    Constraint.create!(name:, category: category.to_s)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    raise "Could not create constraint with category: '#{category}' and name: '#{name}' with error: #{e.message}"
  end
end
