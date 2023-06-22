# frozen_string_literal: true

class AddAutomatedActivityToAudits < ActiveRecord::Migration[6.1]
  def up
    add_column(
      :audits,
      :automated_activity,
      :boolean,
      default: false,
      null: false
    )

    execute(
      "UPDATE audits
      SET automated_activity = TRUE
      WHERE activity_type IN (
        'description_change_validation_request_auto_closed',
        'red_line_boundary_change_validation_request_auto_closed'
      );"
    )

    execute(
      "UPDATE audits AS a
      SET automated_activity = TRUE
      FROM audits AS b
      WHERE a.activity_type = 'updated'
      AND a.activity_information = 'Description'
      AND a.user_id IS NULL
      AND a.api_user_id IS NULL
      AND a.planning_application_id = b.planning_application_id
      AND b.activity_type = 'description_change_validation_request_auto_closed'
      AND b.created_at BETWEEN (a.created_at - INTERVAL '1 second') AND (a.created_at + INTERVAL '1 second');"
    )
  end

  def down
    remove_column :audits, :automated_activity
  end
end
