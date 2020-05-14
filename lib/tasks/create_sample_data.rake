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
  jane_agent = Agent.find_or_create_by!(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    phone: Faker::Base.numerify("+44 7### ######"),
    email: Faker::Internet.email,
    postcode: Faker::Address.postcode,
    address_1: Faker::Address.street_address,
    town: Faker::Address.city
  )

  # Applicant
  jason_applicant = Applicant.find_or_create_by!(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    phone: Faker::Base.numerify("+44 7### ######"),
    email: Faker::Internet.email,
    postcode: Faker::Address.postcode,
    address_1: Faker::Address.street_address,
    town: Faker::Address.city,
    residence_status: true
  )

  # An application with no decisions
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
    agent: jane_agent,
    applicant: jason_applicant,
    user: assessor
  ) do |pa|
    pa.status = :awaiting_determination
    pa.description = "Installation of new external insulated render to be added"
  end

  bowen_planning_application.update(target_date: 2.weeks.from_now)

  # An application with an assessor decision
  college_site = Site.find_or_create_by!(
    address_1: "90A College Road",
    town: "Southwark",
    county: "London",
    postcode: "SE21 7NA"
  )

  college_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: college_site,
    agent: jane_agent,
    applicant: jason_applicant,
    user: assessor
  ) do |pa|
    pa.status = :determined
    pa.description = "Construction of a single storey rear extension"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  college_planning_application.update(target_date: 1.week.from_now)

  unless college_planning_application.assessor_decision
    college_assessor_decision = Decision.new(user: assessor)
    college_assessor_decision.mark_granted
    college_planning_application.decisions << college_assessor_decision
  end

  # An application with an assessor and reviewer decision
  bellenden_site = Site.find_or_create_by!(
    address_1: "150 Bellenden Road",
    town: "Southwark",
    county: "London",
    postcode: "SE15 4QY"
  )

  bellenden_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: bellenden_site,
    agent: jane_agent,
    applicant: jason_applicant,
    ward: "Rye Lane",
    user: assessor
  ) do |pa|
    pa.description = "Construction of a single storey side extension"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  bellenden_planning_application.update(target_date: 3.weeks.from_now)

  unless bellenden_planning_application.assessor_decision
    bellenden_assessor_decision = Decision.new(user: assessor)
    bellenden_assessor_decision.mark_granted
    bellenden_planning_application.decisions << bellenden_assessor_decision
  end

  unless bellenden_planning_application.reviewer_decision
    bellenden_reviewer_decision = Decision.new(user: reviewer)
    bellenden_reviewer_decision.mark_granted
    bellenden_planning_application.decisions << bellenden_reviewer_decision
  end

  # An application with an assessor and reviewer decision
  james_site = Site.find_or_create_by!(
    address_1: "186 St James Road",
    town: "Southwark",
    county: "London",
    postcode: "SE1 5LN"
  )

  james_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: james_site,
    agent: jane_agent,
    ward: "South Bermondsey",
    applicant: jason_applicant
  ) do |pa|
    pa.description = "Single storey rear extension and rear dormer extension"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  unless james_planning_application.assessor_decision
    james_assessor_decision = Decision.new(user: assessor)
    james_assessor_decision.mark_refused
    james_planning_application.decisions << james_assessor_decision
  end

  unless james_planning_application.reviewer_decision
    james_reviewer_decision = Decision.new(user: reviewer)
    james_reviewer_decision.mark_granted
    james_planning_application.decisions << james_reviewer_decision
  end
end
