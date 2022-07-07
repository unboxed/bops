# frozen_string_literal: true

class AddPostValidationToValidationRequests < ActiveRecord::Migration[6.1]
  class DescriptionChangeValidationRequest < ApplicationRecord
    belongs_to :planning_application
  end

  VALIDATION_REQUEST_TABLES = %i[
    description_change_validation_requests
    additional_document_validation_requests
    other_change_validation_requests
    red_line_boundary_change_validation_requests
    replacement_document_validation_requests
  ].freeze

  def up
    VALIDATION_REQUEST_TABLES.each do |table_name|
      add_column table_name, :post_validation, :boolean, default: false, null: false
    end

    DescriptionChangeValidationRequest.find_each do |validation_request|
      in_assessment_at = validation_request.planning_application.in_assessment_at

      if in_assessment_at && (validation_request.created_at > in_assessment_at)
        validation_request.update(post_validation: true)
      else
        validation_request.update(post_validation: false)
      end
    end
  end

  def down
    VALIDATION_REQUEST_TABLES.each do |table_name|
      remove_column table_name, :post_validation, :boolean
    end
  end
end
