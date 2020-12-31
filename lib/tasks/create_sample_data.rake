# frozen_string_literal: true

desc "Create sample data for testing"
task create_sample_data: :environment do
  require "faker"

  if Rails.env.production? && ENV["FORCE_SAMPLE_DATA"] != "yes"
    raise <<-TEXT
      You cannot create sample data in the production.
      Set FORCE_SAMPLE_DATA=yes to override this check
    TEXT
  end

  # For now, each application will have the same set of policy considerations
  path = Rails.root.join("spec/fixtures/files/permitted_development.json")
  permitted_development_json = File.read(path)
  pcb = Ripa::PolicyConsiderationBuilder.new(permitted_development_json)
  pc1 = pcb.import
  pc2 = pcb.import
  pc3 = pcb.import
  pc4 = pcb.import

  image_path = "spec/fixtures/images/"
  file_1 = Rails.root.join("#{image_path}existing-first-floor-plan.pdf")
  file_2 = Rails.root.join("#{image_path}existing-roofplan.pdf")
  file_3 = Rails.root.join("#{image_path}proposed-first-floor-plan.pdf")
  file_4 = Rails.root.join("#{image_path}proposed-roofplan.pdf")

  sample_constraints = '{"conservation_area": false,"article4_area": true,"scheduled_monument": false }'

  lambeth = LocalAuthority.find_or_create_by!(
    name: "Lambeth Council",
    subdomain: "lambeth",
    signatory_name: "Christina Thompson",
    signatory_job_title: "Director of Finance & Property",
    enquiries_paragraph: "Postal address: Planning London Borough of Lambeth PO Box 734 Winchester SO23 5DG.",
    email_address: "planning@lambeth.gov.uk",
  )
  southwark = LocalAuthority.find_or_create_by!(
    name: "Southwark Council",
    subdomain: "southwark",
    signatory_name: "Simon Bevan",
    signatory_job_title: "Director of Planning",
    enquiries_paragraph: "Postal address: Planning London Borough of Southwark PO Box 734 Winchester SO23 5DG.",
    email_address: "planning@lambeth.gov.uk",
  )

  bucks = LocalAuthority.find_or_create_by!(
    name: "Buckinghamshire",
    subdomain: "bucks",
    signatory_name: "Steve Bambick",
    signatory_job_title: "Director of Planning",
    enquiries_paragraph: "Postal address: Planning Buckinghamshire Council, Gatehouse Rd, Aylesbury HP19 8FF",
    email_address: "planning@buckinghamshire.gov.uk",
  )

  ApiUser.find_or_create_by!(name: "api_user", token: ENV["API_TOKEN"]) if ENV["API_TOKEN"]

  admin_roles = %i[assessor reviewer]
  local_authorities = [southwark, lambeth, bucks]

  # Add lambeth and southwark specific admins
  local_authorities.each do |authority|
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

      User.find_or_create_by!(email: "#{authority.subdomain}_#{admin_role}2@example.com") do |user|
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

  southwark_assessor = User.find_by!(email: "southwark_assessor@example.com", role: :assessor)

  # A planning application with application_type lawfulness_certificate
  bowen_site = Site.create_with(
    address_1: "47 Bowen Drive",
    town: "Southwark",
    county: "London",
    postcode: "SE21 8NS",
  ).find_or_create_by!(uprn: "465789879")

  bowen_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site_id: bowen_site.id,
    ward: "Dulwich Wood",
    user: southwark_assessor,
    local_authority: southwark,
  ) do |pa|
    pa.description = "Installation of new external insulated render to be added"
  end

  bowen_planning_application.update!(target_date: 2.weeks.from_now)

  # A planning application with application_type lawfulness_certificate
  college_site = Site.create_with(
    address_1: "90A College Road",
    town: "Southwark",
    county: "London",
    postcode: "SE21 7NA",
  ).find_or_create_by!(uprn: "0765675")

  college_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: college_site,
    local_authority: southwark,
    constraints: sample_constraints,
  ) do |pa|
    pa.description = "Construction of a single storey rear extension"
  end

  college_planning_application.update!(target_date: 1.week.from_now)

  # A planning application with application_type lawfulness_certificate
  bellenden_site = Site.create_with(
    address_1: "150 Bellenden Road",
    town: "Southwark",
    county: "London",
    postcode: "SE15 4QY",
  ).find_or_create_by!(uprn: "0765675")

  bellenden_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: bellenden_site,
    ward: "Rye Lane",
    local_authority: southwark,
    constraints: sample_constraints,
    work_status: "existing",
  ) do |pa|
    pa.description = "Construction of a single storey side extension"
  end

  bellenden_planning_application.update!(target_date: 3.weeks.from_now)

  # A planning application with application_type lawfulness_certificate
  james_site = Site.create_with(
    address_1: "186 St James Road",
    town: "Southwark",
    county: "London",
    postcode: "SE1 5LN",
  ).find_or_create_by!(uprn: "3455678643")

  james_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: james_site,
    ward: "South Bermondsey",
    local_authority: southwark,
    constraints: sample_constraints,
  ) do |pa|
    pa.description = "Single storey rear extension and rear dormer extension"
  end

  # A planning application example for lambeth
  lambeth_site = Site.create_with(
    address_1: "2 Streatham High Rd",
    town: "Lambeth",
    county: "London",
    postcode: "SW16 1HT",
  ).find_or_create_by!(uprn: "3453543")

  lambeth_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: lambeth_site,
    ward: "Lambeth",
    work_status: "existing",
    local_authority: lambeth,
    constraints: sample_constraints,
  ) do |pa|
    pa.description = "Single storey rear extension and rear dormer extension"
  end

  # Two planning application examples for bucks
  bucks_site = Site.create_with(
    address_1: "4 Chenies Parade, Little Chalfont",
    town: "Amersham",
    county: "Buckinghamshire",
    postcode: "HP7 9PH",
  ).find_or_create_by!(uprn: "45435435")

  bucks_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: bucks_site,
    ward: "Buckinghamshire",
    work_status: "existing",
    local_authority: bucks,
    constraints: sample_constraints,
  ) do |pa|
    pa.description = "Construction of a single storey side extension"
  end

  bucks_second_site = Site.create_with(
    address_1: "29 Turners Pl, Holmer Green",
    town: "High Wycombe",
    county: "Buckinghamshire",
    postcode: "HP15 6RJ",
  ).find_or_create_by!(uprn: "980900909")

  bucks_second_planning_application = PlanningApplication.find_or_create_by!(
    application_type: :lawfulness_certificate,
    site: bucks_second_site,
    ward: "Buckinghamshire",
    local_authority: bucks,
    constraints: sample_constraints,
  ) do |pa|
    pa.description = "Single storey rear extension and rear dormer extension"
  end

  bowen_pe = bowen_planning_application.create_policy_evaluation
  bowen_pe.policy_considerations << pc1
  bowen_planning_application.policy_evaluation = bowen_pe

  college_pe = college_planning_application.create_policy_evaluation
  college_pe.policy_considerations << pc2
  college_planning_application.policy_evaluation = college_pe

  bellenden_pe = bellenden_planning_application.create_policy_evaluation
  bellenden_pe.policy_considerations << pc3
  bellenden_planning_application.policy_evaluation = bellenden_pe

  james_pe = james_planning_application.create_policy_evaluation
  james_pe.policy_considerations << pc4
  james_planning_application.policy_evaluation = james_pe

  lambeth_pe = lambeth_planning_application.create_policy_evaluation
  lambeth_pe.policy_considerations << pc4
  lambeth_planning_application.policy_evaluation = lambeth_pe

  bucks_pe = bucks_planning_application.create_policy_evaluation
  bucks_pe.policy_considerations << pc4
  bucks_planning_application.policy_evaluation = bucks_pe

  bucks_second_pe = bucks_second_planning_application.create_policy_evaluation
  bucks_second_pe.policy_considerations << pc4
  bucks_second_planning_application.policy_evaluation = bucks_second_pe

  [bowen_planning_application,
   college_planning_application,
   james_planning_application,
   bellenden_planning_application,
   lambeth_planning_application,
   bucks_planning_application,
   bucks_second_planning_application].each do |application|
    document_1 = application.documents.create!(
      tags: Document::TAGS.sample(rand(1..3)),
    )
    document_1.file.attach(io: File.open(file_1),
                           filename: "existing-first-floor-plan.pdf")

    document_2 = application.documents.create!(
      tags: Document::TAGS.sample(rand(1..3)),
    )
    document_2.file.attach(io: File.open(file_2),
                           filename: "existing-roofplan.pdf")

    document_3 = application.documents.create!(
      tags: Document::TAGS.sample(rand(1..3)),
    )
    document_3.file.attach(io: File.open(file_3),
                           filename: "proposed-first-floor-plan.pdf")

    document_4 = application.documents.create!(
      tags: Document::TAGS.sample(rand(1..3)),
    )
    document_4.file.attach(io: File.open(file_4),
                           filename: "proposed-roofplan.pdf")
  end
end
