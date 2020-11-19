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
  plan_1 = Rails.root.join("#{image_path}proposed-section.jpg")
  plan_2 = Rails.root.join("#{image_path}existing-section.png")
  plan_3 = Rails.root.join("#{image_path}existing-floorplan.pdf")
  plan_4 = Rails.root.join("#{image_path}proposed-floorplan.png")

  lambeth = LocalAuthority.find_or_create_by!(
    name: "Lambeth",
    subdomain: "lambeth"
  )
  southwark = LocalAuthority.find_or_create_by!(
    name: "Southwark",
    subdomain: "southwark"
  )

  admin_roles = %i[assessor reviewer]

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{admin_role}@example.com") do |user|
      first_name = Faker::Name.unique.first_name
      last_name = Faker::Name.unique.last_name
      user.name = "#{first_name} #{last_name}"
      user.local_authority = southwark
      if Rails.env.development?
        user.password = user.password_confirmation = "password"
      else
        user.password = user.password_confirmation = SecureRandom.uuid
        user.encrypted_password =
          "$2a$11$uvtPXUB2CmO8WEYm7ajHf.XhZtBsclT/sT45ijLMIELShaZvceW5."
      end

      user.role = admin_role
    end

    User.find_or_create_by!(email: "#{admin_role}2@example.com") do |user|
      first_name = Faker::Name.unique.first_name
      last_name = Faker::Name.unique.last_name
      user.name = "#{first_name} #{last_name}"
      user.local_authority = southwark
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

  local_authorities = [southwark, lambeth]

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

  assessor = User.find_by!(email: "assessor@example.com", role: :assessor)
  reviewer = User.find_by!(email: "reviewer@example.com", role: :reviewer)

  # Agent
  agent = Agent.find_or_create_by!(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    phone: Faker::Base.numerify("+44 7### ######"),
    email: Faker::Internet.email,
    postcode: Faker::Address.postcode,
    address_1: Faker::Address.street_address,
    town: Faker::Address.city
  )

  # Applicant
  applicant = Applicant.find_or_create_by!(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    phone: Faker::Base.numerify("+44 7### ######"),
    email: "bops-team@unboxedconsulting.com",
    postcode: Faker::Address.postcode,
    address_1: Faker::Address.street_address,
    town: Faker::Address.city,
    residence_status: true
  )

  # A planning application with application_type lawfulness_certificate
  bowen_site = Site.find_or_create_by!(
    address_1: "47 Bowen Drive",
    town: "Southwark",
    county: "London",
    postcode: "SE21 8NS"
  )

  bowen_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site_id: bowen_site.id,
    ward: "Dulwich Wood",
    agent: agent,
    applicant: applicant,
    user: assessor,
    local_authority: southwark
  ) do |pa|
    pa.description = "Installation of new external insulated render to be added"
  end

  bowen_planning_application.update(target_date: 2.weeks.from_now)

  # A planning application with application_type lawfulness_certificate
  college_site = Site.find_or_create_by!(
    address_1: "90A College Road",
    town: "Southwark",
    county: "London",
    postcode: "SE21 7NA"
  )

  college_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: college_site,
    agent: agent,
    applicant: applicant,
    local_authority: southwark
  ) do |pa|
    pa.description = "Construction of a single storey rear extension"
  end

  college_planning_application.update(target_date: 1.week.from_now)

  # A planning application with application_type lawfulness_certificate
  bellenden_site = Site.find_or_create_by!(
    address_1: "150 Bellenden Road",
    town: "Southwark",
    county: "London",
    postcode: "SE15 4QY"
  )

  bellenden_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: bellenden_site,
    agent: agent,
    applicant: applicant,
    ward: "Rye Lane",
    local_authority: southwark
  ) do |pa|
    pa.description = "Construction of a single storey side extension"
  end

  bellenden_planning_application.update(target_date: 3.weeks.from_now)

  # A planning application with application_type lawfulness_certificate
  james_site = Site.find_or_create_by!(
    address_1: "186 St James Road",
    town: "Southwark",
    county: "London",
    postcode: "SE1 5LN"
  )

  james_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: james_site,
    agent: agent,
    ward: "South Bermondsey",
    applicant: applicant,
    local_authority: southwark
  ) do |pa|
    pa.description = "Single storey rear extension and rear dormer extension"
  end

  # A planning application example for lambeth
  lambeth_site = Site.find_or_create_by!(
    address_1: "2 Streatham High Rd",
    town: "Lambeth",
    county: "London",
    postcode: "SW16 1HT"
  )

  lambeth_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: lambeth_site,
    agent: agent,
    ward: "Lambeth",
    applicant: applicant,
    local_authority: lambeth
  ) do |pa|
    pa.description = "Bigger bakery because bigger cakes"
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

  [bowen_planning_application,
   college_planning_application,
   james_planning_application,
   bellenden_planning_application,
   lambeth_planning_application].each do |application|
    drawing_1 = application.drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_1.plan.attach(io: File.open(plan_1),
      filename: "proposed-section.jpg"
    )

    drawing_2 = application.drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_2.plan.attach(io: File.open(plan_2),
      filename: "existing-section.png"
    )

    drawing_3 = application.drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_3.plan.attach(io: File.open(plan_3),
      filename: "existing-floorplan.pdf"
    )

    drawing_4 = application.drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_4.plan.attach(io: File.open(plan_4),
      filename: "proposed-floorplan.png"
    )
  end
end
