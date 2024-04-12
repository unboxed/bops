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
