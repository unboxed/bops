# frozen_string_literal: true

class UpdateAutoClosedAudits < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE audits AS a
      SET activity_type = 'description_change_validation_request_auto_closed', activity_information = d.sequence
      FROM description_change_validation_requests AS d
      WHERE a.activity_type = 'auto_closed'
      AND a.planning_application_id = d.planning_application_id
      AND d.auto_closed_at BETWEEN (a.created_at - INTERVAL '1 second') AND (a.created_at + INTERVAL '1 second');"
    )

    execute(
      "UPDATE audits AS a
      SET activity_type = 'red_line_boundary_change_validation_request_auto_closed', activity_information = d.sequence
      FROM red_line_boundary_change_validation_requests AS d
      WHERE a.activity_type = 'auto_closed'
      AND a.planning_application_id = d.planning_application_id
      AND d.auto_closed_at BETWEEN (a.created_at - INTERVAL '1 second') AND (a.created_at + INTERVAL '1 second');"
    )
  end

  def down
    execute(
      "UPDATE audits
      SET activity_type = 'auto_closed', activity_information = NULL
      WHERE activity_type IN (
        'description_change_validation_request_auto_closed',
        'red_line_boundary_change_validation_request_auto_closed'
      );"
    )
  end
end
