# frozen_string_literal: true

desc "Create sample data for testing"
task create_sample_data: :environment do
  admin_user = User.find_by!(email: "admin@example.com")

  admin_roles = %i[assessor reviewer]

  admin_roles.each do |admin_role|
    User.find_or_create_by!(email: "#{admin_role}@example.com") do |user|
      user.name = admin_role.capitalize

      user.password = "password"
      user.password_confirmation = "password"

      user.role = admin_role
    end
  end
end
