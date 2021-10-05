# frozen_string_literal: true

class AddColumnToRedLineBoundaryChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :red_line_boundary_change_validation_requests, :notified_at, :date
  end
end
