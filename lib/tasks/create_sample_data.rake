# frozen_string_literal: true

require "yaml"

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

  admin_roles = %i[assessor reviewer]

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{admin_role}@example.com") do |user|
      first_name = Faker::Name.unique.first_name
      last_name = Faker::Name.unique.last_name
      user.name = "#{first_name} #{last_name}"

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

  locations = YAML.load_file(
    Rails.root.join("lib/assets/sample_applications.yml"))

  DESCRIPTIONS = ["Installation of new external insulated render to be added",
                  "Single storey rear extension and rear dormer extension",
                  "Construction of a single storey rear extension"]

  POLICY_CONSIDERATIONS = [pc1, pc2, pc3, pc4]

  locations.each do |key, value|
    key = Site.find_or_create_by!(
      address_1: value["address_1"],
      town: value["town"],
      county: value["county"],
      postcode: value["postcode"]
    )

    value["application"] = PlanningApplication.find_or_create_by(
      application_type: :lawfulness_certificate,
      site_id: key.id,
      ward: "Dulwich Wood",
      agent: agent,
      applicant: applicant,
      user: assessor
    ) do |pa|
      pa.description = DESCRIPTIONS.sample(rand(1..3))
    end

    pc = POLICY_CONSIDERATIONS.sample(rand(1..3))

    policy_evaluation = value["application"].create_policy_evaluation
    policy_evaluation.policy_considerations << pc
    value["application"].policy_evaluation = policy_evaluation

    drawing_1 = value["application"].drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_1.plan.attach(io: File.open(plan_1),
                          filename: "proposed-section.jpg"
    )

    drawing_2 = value["application"].drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_2.plan.attach(io: File.open(plan_2),
                          filename: "existing-section.png"
    )

    drawing_3 = value["application"].drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_3.plan.attach(io: File.open(plan_3),
                          filename: "existing-floorplan.pdf"
    )

    drawing_4 = value["application"].drawings.create(
      tags: Drawing::TAGS.sample(rand(1..3))
    )
    drawing_4.plan.attach(io: File.open(plan_4),
                          filename: "proposed-floorplan.png"
    )
  end
end
