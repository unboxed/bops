# frozen_string_literal: true

class AddClosedAtToValidationRequests < ActiveRecord::Migration[6.1]
  VALIDATION_REQUEST_TYPES = %w[
    DescriptionChangeValidationRequest
    AdditionalDocumentValidationRequest
    OtherChangeValidationRequest
    RedLineBoundaryChangeValidationRequest
    ReplacementDocumentValidationRequest
  ].freeze

  def up
    add_column :validation_requests, :closed_at, :datetime unless column_exists?(:validation_requests, :closed_at)

    VALIDATION_REQUEST_TYPES.each do |model_name|
      klass = model_name.constantize

      klass.closed.find_each do |request|
        # This is not ideal but it is the most reliable way to predict the closed_at time
        # as no action is taken on a validation request after it has been closed
        request.validation_request.update!(closed_at: request.updated_at)
      rescue ActiveRecord::RecordInvalid => e
        raise "Could not update #{request.class} with ID: #{request.id} with error: #{e.message}"
      end
    end
  end

  def down
    remove_column :validation_requests, :closed_at, :datetime if column_exists?(:validation_requests, :closed_at)
  end
end
