# frozen_string_literal: true

class AddDescriptionToPlanningApplicationPolicySections < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_column :planning_application_policy_sections, :description, :text

      up_only do
        execute <<~SQL
          UPDATE planning_application_policy_sections
          SET description = policy_sections.description
          FROM policy_sections
          WHERE policy_sections.id = planning_application_policy_sections.policy_section_id
        SQL

        change_column_null :planning_application_policy_sections, :description, false
      end
    end
  end
end
