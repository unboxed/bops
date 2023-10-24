# frozen_string_literal: true

class AddPlanningApplicationToValidationRequests < ActiveRecord::Migration[6.1]
  VALIDATION_REQUEST_TYPES = %w[
    DescriptionChangeValidationRequest
    AdditionalDocumentValidationRequest
    OtherChangeValidationRequest
    RedLineBoundaryChangeValidationRequest
    ReplacementDocumentValidationRequest
  ].freeze

  def up
    unless column_exists?(:validation_requests, :planning_application_id)
      add_reference :validation_requests, :planning_application, foreign_key: true
    end

    VALIDATION_REQUEST_TYPES.each do |model_name|
      klass = model_name.constantize

      klass.find_each do |request|
        request.validation_request.update!(planning_application: request.planning_application)
      rescue ActiveRecord::RecordInvalid => e
        raise "Could not update #{request.class} with ID: #{request.id} with error: #{e.message}"
      end
    end
  end

  def down
    remove_reference :validation_requests, :planning_application if column_exists?(:validation_requests,
      :planning_application_id)
  end
end
