# frozen_string_literal: true

require "faker"

email = ->(subdomain, role) { "#{subdomain}_#{role}@example.com" }
password = ->(env) { env.production? ? PasswordGenerator.call : "nw29nfsijrP!P392" }
fixture = ->(file) { YAML.load_file(File.expand_path("seeds/#{file}.yml", __dir__)) }

fixture["local_authorities"].each do |attrs|
  LocalAuthority.find_or_create_by!(attrs.slice("subdomain")) do |lpa|
    lpa.assign_attributes(attrs)
  end
end

LocalAuthority.find_each do |lpa|
  lpa.readonly!
  lpa.api_users.find_or_create_by!(name: lpa.subdomain)

  %w[assessor reviewer administrator].each do |role|
    lpa.users.find_or_create_by!(email: email[lpa.subdomain, role]) do |user|
      user.name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"
      user.password = user.password_confirmation = password[Rails.env]
      user.role = role
      user.otp_required_for_login = false
    end
  end
end

User.find_or_create_by!(role: "global_administrator") do |user|
  user.role = "global_administrator"
  user.password = PasswordGenerator.call
  user.otp_required_for_login = false
  user.name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"
  user.email = "globaladmin@example.com"
end

User.find_each do |user|
  user.confirm unless user.confirmed?
end

fixture["decisions"].each do |attrs|
  Decision.find_or_create_by!(attrs.slice("code")) do |decision|
    decision.assign_attributes(attrs)
  end
end

fixture["reporting_types"].each do |attrs|
  ReportingType.find_or_create_by!(attrs.slice("code")) do |reporting_type|
    reporting_type.assign_attributes(attrs)
  end
end

fixture["application_types"].each do |attrs|
  ApplicationType.find_or_create_by!(attrs.slice("code")) do |application_type|
    application_type.assign_attributes(attrs)
  end
end

fixture["constraints"].each do |category, types|
  types.each do |type|
    Constraint.find_or_create_by!(category:, type:)
  end
end

# Create GPDO information - https://www.legislation.gov.uk/uksi/2015/596/contents
schedule = PolicySchedule.find_or_create_by!(number: 2, name: "Permitted development rights")
data = fixture["gpdo"]
data["en"]["schedules"].first["parts"].each do |part_key, part_data|
  part = schedule.policy_parts.find_or_create_by!(
    number: part_key,
    name: part_data["name"]
  )

  part_data["classes"].each do |class_data|
    policy_class = part.policy_classes.find_or_create_by!(
      section: class_data["section"],
      name: class_data["name"],
      url: class_data["url"]
    )

    class_data["policies_attributes"].each do |section_data|
      policy_class.policy_sections.find_or_create_by!(
        section: section_data["section"].presence || class_data["section"],
        description: section_data["description"]
      )
    end
  end
end
