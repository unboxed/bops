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
    town: "London"
  )

  # Applicant
  jason_applicant = Applicant.find_or_create_by!(
    first_name: Faker::Name.unique.first_name,
    last_name: Faker::Name.unique.last_name,
    phone: Faker::Base.numerify("+44 7### ######"),
    email: Faker::Internet.email,
    postcode: Faker::Address.postcode,
    address_1: Faker::Address.street_address,
    town: "London"
  )

  # An application with no decisions
  stonehenge_site = Site.find_or_create_by!(
    address_1: "Stonehenge",
    town: "Amesbury",
    county: "Wiltshire",
    postcode: "SP4 7DE"
  )

  stonehenge_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site_id: stonehenge_site.id,
    ward: "Glastonbury",
    agent: jane_agent,
    applicant: jason_applicant,
    user: assessor
  ) do |pa|
    pa.status = :awaiting_determination
    pa.description = "Extra stone on top"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  stonehenge_planning_application.update(target_date: 2.weeks.from_now)

  # An application with an assessor decision
  castle_site = Site.find_or_create_by!(
    address_1: "Dover Castle",
    address_2: "Castle Hill",
    town: "Dover",
    county: "Kent",
    postcode: "CT16 1HU"
  )

  castle_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: castle_site,
    agent: jane_agent,
    applicant: jason_applicant,
    user: assessor
  ) do |pa|
    pa.status = :determined
    pa.description = "Extra moat"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  castle_planning_application.update(target_date: 1.week.from_now)

  unless castle_planning_application.assessor_decision
    castle_assessor_decision = Decision.new(user: assessor)
    castle_assessor_decision.mark_granted
    castle_planning_application.decisions << castle_assessor_decision
  end

  # An application with an assessor and reviewer decision
  palace_site = Site.find_or_create_by!(
    address_1: "Buckingham Palace",
    town: "Westminster",
    county: "London",
    postcode: "SW1A 1AA"
  )

  palace_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: palace_site,
    agent: jane_agent,
    applicant: jason_applicant,
    ward: "Victoria",
    user: assessor
  ) do |pa|
    pa.description = "Lean-to"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  palace_planning_application.update(target_date: 3.weeks.from_now)

  unless palace_planning_application.assessor_decision
    palace_assessor_decision = Decision.new(user: assessor)
    palace_assessor_decision.mark_granted
    palace_planning_application.decisions << palace_assessor_decision
  end

  unless palace_planning_application.reviewer_decision
    palace_reviewer_decision = Decision.new(user: reviewer)
    palace_reviewer_decision.mark_granted
    palace_planning_application.decisions << palace_reviewer_decision
  end

  # An application with an assessor and reviewer decision
  pier_site = Site.find_or_create_by!(
    address_1: "Brighton Palace Pier",
    address_2: "Madeira Dr",
    town: "Brighton",
    county: "East Sussex",
    postcode: "BN2 1TW"
  )

  pier_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: pier_site,
    agent: jane_agent,
    applicant: jason_applicant
  ) do |pa|
    pa.description = "Extend pier to reach France"
    pa.reference = "AP/#{rand(-4500)}/#{rand(-100)}"
  end

  unless pier_planning_application.assessor_decision
    pier_assessor_decision = Decision.new(user: assessor)
    pier_assessor_decision.mark_refused
    pier_planning_application.decisions << pier_assessor_decision
  end

  unless pier_planning_application.reviewer_decision
    pier_reviewer_decision = Decision.new(user: reviewer)
    pier_reviewer_decision.mark_granted
    pier_planning_application.decisions << pier_reviewer_decision
  end
end
