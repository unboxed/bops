# frozen_string_literal: true

class UpdateAuditsGeneratedByApiUser < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE audits
      SET api_user_id = 1
      WHERE api_user_id IS NULL
      AND user_id IS NULL
      AND activity_type IN (
        'description_change_validation_request_received',
        'replacement_document_validation_request_received',
        'additional_document_validation_request_received',
        'red_line_boundary_change_validation_request_received',
        'other_change_validation_request_received'
      );"
    )

    execute(
      "UPDATE audits as a
      SET api_user_id = 1
      FROM audits as b
      WHERE a.api_user_id IS NULL
      AND a.user_id IS NULL
      AND a.activity_type = 'uploaded'
      AND a.planning_application_id = b.planning_application_id
      AND b.activity_type = 'replacement_document_validation_request_received'
      AND b.created_at BETWEEN (a.created_at - INTERVAL '1 second') AND (a.created_at + INTERVAL '1 second');"
    )
  end

  def down; end
end
