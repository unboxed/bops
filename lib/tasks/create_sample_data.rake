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
    name: "Jane Agent",
    email: "agent@example.com",
    phone: "0759222222"
  )

  # Applicant
  jason_applicant = Applicant.find_or_create_by!(
    name: "Jason Applicant",
    email: "applicant@example.com",
    phone: "0759111111"
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
  ) do |pa|
    pa.submission_date = Date.current - 1.week
    pa.description = "Extra stone on top"
  end

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
    applicant: jason_applicant
  ) do |pa|
    pa.submission_date = Date.current - 1.week
    pa.description = "Extra moat"
    pa.code = "AP/45/1880"
  end

  unless castle_planning_application.assessor_decision
    castle_assessor_decision = Decision.new(user: assessor)
    castle_assessor_decision.mark_granted
    castle_planning_application.decisions << castle_assessor_decision
  end

  # An application with an assessor and reviewer decision
  palace_site = Site.find_or_create_by!(
    address_1: "Buckhingham Palace",
    town: "Westminster",
    county: "London",
    postcode: "SW1A 1AA"
  )

  palace_planning_application = PlanningApplication.find_or_create_by(
    application_type: :lawfulness_certificate,
    site: palace_site
  ) do |pa|
    pa.submission_date = Date.current - 2.weeks
    pa.description = "Lean-to"
  end

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
    site: pier_site
  ) do |pa|
    pa.submission_date = Date.current - 4.weeks
    pa.description = "Extend pier to reach France"
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
