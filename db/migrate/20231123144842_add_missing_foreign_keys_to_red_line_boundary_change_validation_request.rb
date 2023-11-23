# frozen_string_literal: true

class AddMissingForeignKeysToRedLineBoundaryChangeValidationRequest < ActiveRecord::Migration[7.0]
  def change
    change_column :red_line_boundary_change_validation_requests, :planning_application_id, :bigint, null: false
    change_column :red_line_boundary_change_validation_requests, :user_id, :bigint, null: false

    add_foreign_key :red_line_boundary_change_validation_requests, :planning_applications
    add_foreign_key :red_line_boundary_change_validation_requests, :users
  end
end
