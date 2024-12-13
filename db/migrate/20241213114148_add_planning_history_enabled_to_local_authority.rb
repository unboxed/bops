# frozen_string_literal: true

class AddPlanningHistoryEnabledToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_column :local_authorities, :planning_history_enabled, :boolean

      up_only do
        execute <<~SQL
          UPDATE local_authorities
          SET planning_history_enabled = CASE
          WHEN subdomain = 'buckinghamshire' THEN TRUE
          WHEN subdomain = 'lambeth' THEN TRUE
          ELSE FALSE
          END
        SQL

        change_column_default :local_authorities, :planning_history_enabled, false
        change_column_null :local_authorities, :planning_history_enabled, false
      end
    end
  end
end
