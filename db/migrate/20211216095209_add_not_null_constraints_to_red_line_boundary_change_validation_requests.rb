# frozen_string_literal: true

class AddNotNullConstraintsToRedLineBoundaryChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    change_column_null :red_line_boundary_change_validation_requests, :new_geojson, false
    change_column_null :red_line_boundary_change_validation_requests, :reason, false
  end
end
