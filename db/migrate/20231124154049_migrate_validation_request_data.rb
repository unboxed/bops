# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class MigrateValidationRequestData < ActiveRecord::Migration[7.0]
  class AdditionalDocumentValidationRequest < ValidationRequest
    # has_one :validation_request, as: :requestable
  end

  class ReplacementDocumentValidationRequest < ValidationRequest
    has_one :validation_request, as: :requestable
  end

  class DescriptionChangeValidationRequest < ValidationRequest
    has_one :validation_request, as: :requestable
  end

  class RedLineBoundaryChangeValidationRequest < ValidationRequest
    has_one :validation_request, as: :requestable
  end

  class OtherChangeValidationRequest < ValidationRequest
    has_one :validation_request, as: :requestable
  end

  class ValidationRequest < ApplicationRecord
    before_update :reset_fee_invalidation

    store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

    def reset_fee_invalidation
    end
  end

  def up
    change_table :validation_requests, bulk: true do |t|
      t.string :state
      t.references :user
      t.boolean :post_validation, default: false, null: false
      t.boolean :applicant_approved
      t.text :reason
      t.string :applicant_rejection_reason
      t.text :applicant_response
      t.datetime :notified_at
      t.datetime :cancelled_at
      t.text :cancel_reason
      t.boolean :auto_closed, null: false, default: false
      t.boolean :fee_item
      t.datetime :auto_closed_at
      t.references :old_document, foreign_key: {to_table: :documents}
      t.integer :sequence
      t.jsonb :specific_attributes
    end

    rename_column :validation_requests, :requestable_type, :type
    change_column :validation_requests, :requestable_id, :bigint, null: true

    AdditionalDocumentValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, type: "AdditionalDocumentValidationRequest")
      validation_request.assign_attributes(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.document_request_reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        document_request_type: request.document_request_type
      )

      validation_request.save(validate: false)

      request.documents.each { |document| document.update(owner: request) }
    end

    ReplacementDocumentValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, type: "ReplacementDocumentValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        old_document_id: request.old_document_id,
        new_document_id: request.new_document_id,
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence
      )

      validation_request.save(validate: false)

      request.documents.each { |document| document.update(owner: request) }
    end

    DescriptionChangeValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, type: "DescriptionChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        proposed_description: request.proposed_description,
        previous_description: request.previous_description,
        applicant_approved: request.approved,
        applicant_rejection_reason: request.rejection_reason,
        auto_closed: request.auto_closed,
        auto_closed_at: request.auto_closed_at
      )

      validation_request.save(validate: false)
    end

    RedLineBoundaryChangeValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, type: "RedLineBoundaryChangeValidationRequest")

      validation_request&.assign_attributes(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        new_geojson: request.new_geojson,
        original_geojson: request.original_geojson,
        applicant_approved: request.approved,
        applicant_rejection_reason: request.rejection_reason,
        auto_closed: request.auto_closed,
        auto_closed_at: request.auto_closed_at
      )

      validation_request&.save(validate: false)
    end

    OtherChangeValidationRequest.where(fee_item: true).find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, type: "OtherChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        type: "FeeChangeValidationRequest",
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.summary,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        suggestion: request.suggestion
      )

      validation_request.save(validate: false)
    end

    OtherChangeValidationRequest.where(fee_item: false).find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "OtherChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.summary,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        suggestion: request.suggestion
      )

      validation_request.save(validate: false)
    end

    remove_foreign_key :additional_document_validation_requests, :planning_applications
    remove_foreign_key :additional_document_validation_requests, :users

    remove_foreign_key :replacement_document_validation_requests, :planning_applications
    remove_foreign_key :replacement_document_validation_requests, :users

    remove_foreign_key :description_change_validation_requests, :planning_applications
    remove_foreign_key :description_change_validation_requests, :users

    remove_foreign_key :red_line_boundary_change_validation_requests, :planning_applications
    remove_foreign_key :red_line_boundary_change_validation_requests, :users

    remove_foreign_key :other_change_validation_requests, :planning_applications
    remove_foreign_key :other_change_validation_requests, :users

    remove_reference :validation_requests, :requestable
    remove_column :validation_requests, :fee_item

    remove_reference :documents, :replacement_document_validation_request
    remove_reference :documents, :additional_document_validation_request

    drop_table :other_change_validation_requests
    drop_table :description_change_validation_requests
    drop_table :red_line_boundary_change_validation_requests
    drop_table :replacement_document_validation_requests
    drop_table :additional_document_validation_requests
  end

  def down
    create_table :additional_document_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, default: "pending", null: false
      t.string :document_request_type
      t.string :document_request_reason
      t.integer :sequence
      t.datetime :notified_at
      t.string :cancel_reason
      t.datetime :cancelled_at
      t.boolean :post_validation, default: false, null: false

      t.timestamps
    end

    add_reference :documents, :additional_document_validation_request, foreign_key: true

    AdditionalDocumentValidationRequest.find_each do |request|
      new_request = AdditionalDocumentValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        document_request_reason: request.reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        document_request_type: request.document_request_type,
        planning_application_id: request.planning_application_id
      )

      Document.find_by(validation_request_id: request.id)&.update(additional_document_validation_request_id: new_request.id)

      request.update(
        requestable_id: new_request.id,
        request_type: "AdditionalDocumentValidationRequest"
      )
    end

    create_table :replacement_document_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :old_document, null: false, foreign_key: {to_table: :documents}
      t.references :new_document, foreign_key: {to_table: :documents}
      t.string :state, default: "pending", null: false
      t.string :reason
      t.integer :sequence
      t.datetime :notified_at
      t.string :cancel_reason
      t.datetime :cancelled_at
      t.boolean :post_validation, default: false, null: false

      t.timestamps
    end

    add_reference :documents, :replacement_document_validation_request, foreign_key: true

    ReplacementDocumentValidationRequest.find_each do |request|
      new_request = ReplacementDocumentValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        old_document_id: request.old_document_id,
        new_document_id: request.new_document_id,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        planning_application_id: request.planning_application_id
      )

      Document.find_by(validation_request_id: request.id)&.update(replacement_document_validation_request_id: new_request.id)

      request.update(
        requestable_id: new_request.id,
        request_type: "ReplacementDocumentValidationRequest"
      )
    end

    create_table :red_line_boundary_change_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :new_geojson
      t.jsonb :original_geojson
      t.string :state, default: "pending", null: false
      t.string :reason
      t.integer :sequence
      t.datetime :notified_at
      t.string :cancel_reason
      t.datetime :cancelled_at
      t.boolean :post_validation, default: false, null: false
      t.datetime :auto_closed_at
      t.boolean :auto_closed, default: false, null: false
      t.boolean :approved
      t.string :rejection_reason

      t.timestamps
    end

    RedLineBoundaryChangeValidationRequest.find_each do |request|
      new_request = RedLineBoundaryChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        new_geojson: request.new_geojson,
        original_geojson: request.original_geojson,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        auto_closed_at: request.auto_closed_at,
        auto_closed: request.auto_closed,
        approved: request.applicant_approved,
        rejection_reason: request.applicant_rejection_reason,
        reason: request.reason,
        planning_application_id: request.planning_application_id
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "RedLineBoundaryChangeValidationRequest"
      )
    end

    create_table :description_change_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, default: "pending", null: false
      t.string :reason
      t.integer :sequence
      t.datetime :notified_at
      t.string :cancel_reason
      t.datetime :cancelled_at
      t.boolean :post_validation, default: false, null: false
      t.datetime :auto_closed_at
      t.boolean :auto_closed, default: false, null: false
      t.boolean :approved
      t.string :rejection_reason
      t.string :proposed_description
      t.string :previous_description

      t.timestamps
    end

    DescriptionChangeValidationRequest.find_each do |request|
      new_request = DescriptionChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        auto_closed_at: request.auto_closed_at,
        auto_closed: request.auto_closed,
        approved: request.applicant_approved,
        rejection_reason: request.applicant_rejection_reason,
        reason: request.reason,
        planning_application_id: request.planning_application_id
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "DescriptionChangeValidationRequest"
      )
    end

    create_table :other_change_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, default: "pending", null: false
      t.string :summary
      t.string :suggestion
      t.string :response
      t.integer :sequence
      t.datetime :notified_at
      t.string :cancel_reason
      t.datetime :cancelled_at
      t.boolean :post_validation, default: false, null: false
      t.boolean :fee_item, default: false, null: false

      t.timestamps
    end

    OtherChangeValidationRequest.find_each do |request|
      new_request = OtherChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        valid_fee: false,
        summary: request.reason,
        suggestion: request.specific_attributes["suggestion"],
        planning_application_id: request.planning_application_id
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "OtherChangeValidationRequest"
      )
    end

    FeeChangeValidationRequest.find_each do |request|
      new_request = OtherChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        fee_item: true,
        summary: request.reason,
        suggestion: request.specific_attributes["suggestion"],
        planning_application_id: request.planning_application_id
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "OtherChangeValidationRequest"
      )
    end

    change_table :validation_requests, bulk: true do |t|
      t.remove :state
      t.remove :user_id
      t.remove :post_validation
      t.remove :applicant_approved
      t.remove :reason
      t.remove :applicant_rejection_reason
      t.remove :applicant_response
      t.remove :notified_at
      t.remove :cancelled_at
      t.remove :cancel_reason
      t.remove :auto_closed
      t.remove :auto_closed_at
      t.remove :old_document_id
      t.remove :new_document_id
      t.remove :sequence
      t.remove :specific_attributes
      t.bigint :requestable_id
    end

    rename_column :validation_requests, :type, :requestable_type
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
