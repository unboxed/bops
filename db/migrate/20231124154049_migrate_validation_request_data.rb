# frozen_string_literal: true

class MigrateValidationRequestData < ActiveRecord::Migration[7.0]
  class AdditionalDocumentValidationRequest < ApplicationRecord
    has_one :validation_request, as: :requestable
  end

  class ReplacementDocumentValidationRequest < ApplicationRecord
    has_one :validation_request, as: :requestable
  end

  class DescriptionChangeValidationRequest < ApplicationRecord
    has_one :validation_request, as: :requestable
  end

  class RedLineBoundaryChangeValidationRequest < ApplicationRecord
    has_one :validation_request, as: :requestable
  end

  class OtherChangeValidationRequest < ApplicationRecord
    has_one :validation_request, as: :requestable
  end

  class ValidationRequest < ApplicationRecord
    before_update :reset_fee_invalidation

    store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

    def reset_fee_invalidation
    end
  end

  def up
    add_reference :documents, :validation_request, foreign_key: true

    AdditionalDocumentValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "AdditionalDocumentValidationRequest")
      validation_request.assign_attributes(
        state: request.state,
        request_type: "additional_document",
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

      Document.find_by(additional_document_validation_request_id: request.id)&.update(validation_request_id: validation_request.id)
    end

    ReplacementDocumentValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "ReplacementDocumentValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        request_type: "replacement_document",
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

      Document.find_by(replacement_document_validation_request_id: request)&.update(validation_request_id: validation_request.id)
    end

    DescriptionChangeValidationRequest.find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "DescriptionChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        request_type: "description_change",
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
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "RedLineBoundaryChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        request_type: "red_line_boundary_change",
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

      validation_request.save(validate: false)
    end

    OtherChangeValidationRequest.where(fee_item: true).find_each do |request|
      validation_request = ValidationRequest.find_by(requestable_id: request.id, request_type: "OtherChangeValidationRequest")

      validation_request.assign_attributes(
        state: request.state,
        request_type: "fee_change",
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
        request_type: "other_change",
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

    remove_reference :documents, :additional_document_validation_request
    remove_reference :documents, :replacement_document_validation_request

    drop_table :additional_document_validation_requests, if_exists: true
    drop_table :replacement_document_validation_requests, if_exists: true
    drop_table :description_change_validation_requests, if_exists: true
    drop_table :red_line_boundary_change_validation_requests, if_exists: true
    drop_table :other_change_validation_requests, if_exists: true

    remove_reference :validation_requests, :requestable
  end

  def down
    change_table :validation_request, bulk: true do |t|
      t.bigint :requestable_id
    end

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

    ValidationRequest.where(request_type: "additional_document").each do |request|
      new_request = AdditionalDocumentValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        document_request_reason: request.document_request_reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        document_request_type: request.document_request_type
      )

      Document.find_by(validation_request_id: request.id).update(additional_document_validation_request_id: new_request.id)

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

    ValidationRequest.where(request_type: "replacement_document").each do |request|
      new_request = ReplacementDocumentValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        old_document_id: request.old_document_id,
        new_document_id: request.new_document_id,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence
      )

      Document.find_by(validation_request_id: request.id).update(replacement_document_validation_request_id: new_request.id)

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

    ValidationRequest.where(request_type: "red_line_boundary_change").each do |request|
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
        reason: request.reason
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

    ValidationRequest.where(request_type: "description_change").each do |request|
      new_request = RedLineBoundaryChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        auto_closed_at: request.auto_closed_at,
        auto_closed: request.auto_closed,
        proposed_description: request.proposed_description,
        previous_description: request.previous_description,
        approved: request.applicant_approved,
        rejection_reason: request.applicant_rejection_reason,
        reason: request.reason
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
      t.boolean :valid_fee, default: false, null: false

      t.timestamps
    end

    ValidationRequest.where(request_type: "other_change").each do |request|
      new_request = OtherChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        valid_fee: false,
        summary: request.summary,
        suggestion: request.reason
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "OtherChangeValidationRequest"
      )
    end

    ValidationRequest.where(request_type: "fee_change").each do |request|
      new_request = OtherChangeValidationRequest.create(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        valid_fee: true,
        summary: request.summary,
        suggestion: request.reason
      )

      request.update(
        requestable_id: new_request.id,
        request_type: "OtherChangeValidationRequest"
      )
    end

    rename_column :validation_requests, :request_type, :requestable_type
  end
end
