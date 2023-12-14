# frozen_string_literal: true

require "faker"

lambeth = LocalAuthority.find_or_create_by!(
  council_code: "LBH",
  subdomain: "lambeth",
  short_name: "Lambeth",
  council_name: "Lambeth Council",
  applicants_url: "http://lambeth.bops-applicants.localhost:3001",
  signatory_name: "Christina Thompson",
  signatory_job_title: "Director of Finance & Property",
  enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@lambeth.gov.uk",
  feedback_email: "digitalplanning@lambeth.gov.uk",
  press_notice_email: "digitalplanning@lambeth.gov.uk"
)
southwark = LocalAuthority.find_or_create_by!(
  council_code: "SWK",
  subdomain: "southwark",
  short_name: "Southwark",
  council_name: "Southwark Council",
  applicants_url: "http://southwark.bops-applicants.localhost:3001",
  signatory_name: "Stephen Platts",
  signatory_job_title: "Director of Planning and Growth",
  enquiries_paragraph: "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG",
  email_address: "planning@southwark.gov.uk",
  feedback_email: "digital.projects@southwark.gov.uk",
  press_notice_email: "digital.projects@southwark.gov.uk"
)

buckinghamshire = LocalAuthority.find_or_create_by!(
  council_code: "BUC",
  subdomain: "buckinghamshire",
  short_name: "Buckinghamshire",
  council_name: "Buckinghamshire Council",
  applicants_url: "http://buckinghamshire.bops-applicants.localhost:3001",
  signatory_name: "Steve Bambick",
  signatory_job_title: "Director of Planning",
  enquiries_paragraph: "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF",
  email_address: "planning@buckinghamshire.gov.uk",
  feedback_email: "planning.digital@buckinghamshire.gov.uk",
  press_notice_email: "planning.digital@buckinghamshire.gov.uk"
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
  {
    name: "lawfulness_certificate",
    steps: %w[validation assessment review],
    assessment_details: %w[
      summary_of_work
      site_description
      consultation_summary
      additional_evidence
      past_applications
    ],
    consistency_checklist: %w[
      description_matches_documents
      documents_consistent
      proposal_details_match_documents
      site_map_correct
    ]
  },
  {
    name: "prior_approval", part: 1, section: "A",
    steps: %w[validation consultation assessment review],
    assessment_details: %w[
      summary_of_work
      site_description
      additional_evidence
      publicity_summary
      amenity
      past_applications
    ],
    consistency_checklist: %w[
      description_matches_documents
      documents_consistent
      proposal_details_match_documents
      proposal_measurements_match_documents
      site_map_correct
    ]
  },
  {
    name: "planning_permission",
    features: {"permitted_development_rights" => false},
    steps: %w[validation consultation assessment review],
    assessment_details: %w[
      summary_of_work
      site_description
      additional_evidence
      consultation_summary
      publicity_summary
      past_applications
    ],
    consistency_checklist: %w[
      description_matches_documents
      documents_consistent
      proposal_details_match_documents
      site_map_correct
    ]
  }
]

application_types.each do |attrs|
  ApplicationType.find_or_create_by!(attrs)
end

constraints_list = {
  central_activities_zone: [
    "article4_caz"
  ],
  ecology: %w[
    nature_asnw
    nature_sac
    nature_sssi
  ],
  general_policy: %w[
    article4
    road_classified
  ],
  heritage_and_conservation: %w[
    designated_aonb
    designated_conservationarea
    designated_nationalpark
    designated_spa
    designated_whs
    listed
    locallylisted
    monument
    registeredpark
  ],
  trees: [
    "tpo"
  ],
  other: [
    "designated_nationalpark_broads"
  ]
}

constraints_list.each do |category, types|
  types.each do |type|
    Constraint.find_or_create_by!(type:, category: category.to_s)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    raise "Could not create constraint with category: '#{category}' and type: '#{type}' with error: #{e.message}"
  end
end
