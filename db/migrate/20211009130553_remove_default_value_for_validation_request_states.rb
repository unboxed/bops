# frozen_string_literal: true

class RemoveDefaultValueForValidationRequestStates < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:description_change_validation_requests, :state, from: "pending", to: nil)
    change_column_default(:additional_document_validation_requests, :state, from: "pending", to: nil)
    change_column_default(:other_change_validation_requests, :state, from: "pending", to: nil)
    change_column_default(:red_line_boundary_change_validation_requests, :state, from: "pending", to: nil)
    change_column_default(:replacement_document_validation_requests, :state, from: "pending", to: nil)
  end
end
