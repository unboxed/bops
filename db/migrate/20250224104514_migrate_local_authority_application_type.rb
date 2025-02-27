# frozen_string_literal: true

class MigrateLocalAuthorityApplicationType < ActiveRecord::Migration[7.2]
  def change
    up_only do
      PlanningApplication.find_each do |planning_application|
        next unless planning_application.local_authority_id.present? && planning_application.application_type_id.present?

        LocalAuthority::ApplicationType.find_or_create_by!(
          local_authority_id: planning_application.local_authority_id,
          application_type_id: planning_application.application_type_id
        )
      end
    end
  end
end
