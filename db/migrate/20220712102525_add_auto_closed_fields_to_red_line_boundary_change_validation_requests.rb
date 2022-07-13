# frozen_string_literal: true

class AddAutoClosedFieldsToRedLineBoundaryChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    change_table :red_line_boundary_change_validation_requests, bulk: true do |t|
      t.boolean :auto_closed, default: false, null: false
      t.datetime :auto_closed_at
    end
  end
end
