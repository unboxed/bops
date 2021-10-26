# frozen_string_literal: true

class AddCancelFieldsToValidationRequestTables < ActiveRecord::Migration[6.1]
  VALIDATION_REQUEST_TABLES = %i[
    description_change_validation_requests
    additional_document_validation_requests
    other_change_validation_requests
    red_line_boundary_change_validation_requests
    replacement_document_validation_requests
  ].freeze

  def change
    VALIDATION_REQUEST_TABLES.each do |table_name|
      add_column table_name, :cancel_reason, :text
      add_column table_name, :cancelled_at, :datetime
    end
  end
end
