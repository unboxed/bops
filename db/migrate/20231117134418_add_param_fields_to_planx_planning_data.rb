# frozen_string_literal: true

class AddParamFieldsToPlanxPlanningData < ActiveRecord::Migration[7.0]
  def up
    add_column :planx_planning_data, :params_v1, :jsonb
    add_column :planx_planning_data, :params_v2, :jsonb

    execute <<-SQL
      UPDATE planx_planning_data
      SET params_v1 = planning_applications.audit_log
      FROM planning_applications
      WHERE planx_planning_data.planning_application_id = planning_applications.id
        AND planning_applications.audit_log IS NOT NULL;
    SQL
  end

  def down
    remove_column :planx_planning_data, :params_v1, :jsonb
    remove_column :planx_planning_data, :params_v2, :jsonb
  end
end
