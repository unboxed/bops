# frozen_string_literal: true

desc "Create sample data for testing"
task create_sample_data: :environment do
  require "faker"

  admin_user = User.find_by!(email: "admin@example.com")

  admin_roles = %i[assessor reviewer]

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{admin_role}@example.com") do |user|
      user.name = Faker::Name.unique.name

      user.password = "password"
      user.password_confirmation = "password"

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
    email: Faker::Internet.email,
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
    user: assessor
  ) do |pa|
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
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
    user: assessor
  ) do |pa|
    pa.description = "Construction of a single storey rear extension"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
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
    user: assessor
  ) do |pa|
    pa.description = "Construction of a single storey side extension"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
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
    applicant: applicant
  ) do |pa|
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
    pa.description = "Single storey rear extension and rear dormer extension"
  end
end
