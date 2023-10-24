# frozen_string_literal: true

class CreateValidationRequests < ActiveRecord::Migration[6.1]
  VALIDATION_REQUEST_TYPES = %w[
    DescriptionChangeValidationRequest
    AdditionalDocumentValidationRequest
    OtherChangeValidationRequest
    RedLineBoundaryChangeValidationRequest
    ReplacementDocumentValidationRequest
  ].freeze

  def create_validation_request(id:, type:)
    ValidationRequest.create!(requestable_id: id, requestable_type: type)
  end

  def up
    create_table :validation_requests do |t|
      t.bigint :requestable_id, null: false
      t.string :requestable_type, null: false

      t.timestamps
    end

    add_index :validation_requests, %i[requestable_type requestable_id], unique: true

    VALIDATION_REQUEST_TYPES.each do |model_name|
      klass = model_name.constantize

      klass.all.find_each do |validation_request|
        create_validation_request(id: validation_request.id, type: klass)
      end
    end
  end

  def down
    drop_table :validation_requests if table_exists?(:validation_requests)
  end
end
