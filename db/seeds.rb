# frozen_string_literal: true

require "faker"

LocalAuthority.find_or_create_by!(subdomain: "lambeth") do |la|
  la.council_code = "LBH"
  la.short_name = "Lambeth"
  la.council_name = "Lambeth Council"
  la.applicants_url = "http://lambeth.bops-applicants.localhost:3001"
  la.signatory_name = "Christina Thompson"
  la.signatory_job_title = "Director of Finance & Property"
  la.enquiries_paragraph = "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG"
  la.email_address = "planning@lambeth.gov.uk"
  la.feedback_email = "digitalplanning@lambeth.gov.uk"
  la.press_notice_email = "digitalplanning@lambeth.gov.uk"
end

LocalAuthority.find_or_create_by!(subdomain: "southwark") do |la|
  la.council_code = "SWK"
  la.short_name = "Southwark"
  la.council_name = "Southwark Council"
  la.applicants_url = "http://southwark.bops-applicants.localhost:3001"
  la.signatory_name = "Stephen Platts"
  la.signatory_job_title = "Director of Planning and Growth"
  la.enquiries_paragraph = "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG"
  la.email_address = "planning@southwark.gov.uk"
  la.feedback_email = "digital.projects@southwark.gov.uk"
  la.press_notice_email = "digital.projects@southwark.gov.uk"
end

LocalAuthority.find_or_create_by!(subdomain: "buckinghamshire") do |la|
  la.council_code = "BUC"
  la.short_name = "Buckinghamshire"
  la.council_name = "Buckinghamshire Council"
  la.applicants_url = "http://buckinghamshire.bops-applicants.localhost:3001"
  la.signatory_name = "Steve Bambick"
  la.signatory_job_title = "Director of Planning"
  la.enquiries_paragraph = "Planning, Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF"
  la.email_address = "planning@buckinghamshire.gov.uk"
  la.feedback_email = "planning.digital@buckinghamshire.gov.uk"
  la.press_notice_email = "planning.digital@buckinghamshire.gov.uk"
end

admin_roles = %i[assessor reviewer administrator]
local_authorities = LocalAuthority.all

local_authorities.each do |authority|
  authority.readonly!

  authority.api_users.find_or_create_by!(name: authority.subdomain)

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
