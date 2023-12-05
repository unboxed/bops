# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class MigrateValidationRequestData < ActiveRecord::Migration[7.0]
  class Document < ApplicationRecord
    def reset_replacement_document_validation_request_update_counter!
    end
  end

  class AdditionalDocumentValidationRequest < ApplicationRecord
  end

  class ReplacementDocumentValidationRequest < ApplicationRecord
  end

  class RedLineBoundaryChangeValidationRequest < ApplicationRecord
  end

  class DescriptionChangeValidationRequest < ApplicationRecord
  end

  class OtherChangeValidationRequest < ApplicationRecord
  end

  class ValidationRequest < ApplicationRecord
    store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

    before_update :reset_fee_invalidation

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

    change_column :validation_requests, :requestable_id, :bigint, null: true

    validation_request = Class.new(ActiveRecord::Base) do
      self.table_name = "validation_requests"
      store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]
    end

    advr = Class.new(ActiveRecord::Base) { self.table_name = "additional_document_validation_requests" }

    advr.all.find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "AdditionalDocumentValidationRequest")
      vr.assign_attributes(
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

      vr.save(validate: false)

      Document.where(additional_document_validation_request_id: request.id).each do |document|
        document.update(owner_id: vr.id, owner_type: "ValidationRequest")
      end
    end

    rdvr = Class.new(ActiveRecord::Base) { self.table_name = "replacement_document_validation_requests" }

    rdvr.all.find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "ReplacementDocumentValidationRequest")

      vr.assign_attributes(
        state: request.state,
        old_document_id: request.old_document_id,
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.reason,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence
      )

      vr.save(validate: false)

      if request.new_document_id.present?
        Document.find(request.new_document_id).update(owner_id: vr.id, owner_type: "ValidationRequest")
      end
    end

    dcvr = Class.new(ActiveRecord::Base) { self.table_name = "description_change_validation_requests" }

    dcvr.all.find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "DescriptionChangeValidationRequest")

      vr.assign_attributes(
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

      vr.save(validate: false)
    end

    rlbcvr = Class.new(ActiveRecord::Base) { self.table_name = "red_line_boundary_change_validation_requests" }

    rlbcvr.all.find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "RedLineBoundaryChangeValidationRequest")

      vr.assign_attributes(
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

      vr.save(validate: false)
    end

    ocvr = Class.new(ActiveRecord::Base) { self.table_name = "other_change_validation_requests" }

    ocvr.all.where(fee_item: true).find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "OtherChangeValidationRequest")

      vr.assign_attributes(
        state: request.state,
        requestable_type: "FeeChangeValidationRequest",
        user_id: request.user_id,
        post_validation: request.post_validation,
        reason: request.summary,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        suggestion: request.suggestion
      )

      vr.save(validate: false)
    end

    ocvr.all.where(fee_item: false).find_each do |request|
      vr = validation_request.find_by(requestable_id: request.id, requestable_type: "OtherChangeValidationRequest")

      vr.assign_attributes(
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

      vr.save(validate: false)
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

    rename_column :validation_requests, :requestable_type, :type

    remove_reference :documents, :replacement_document_validation_request
    remove_reference :documents, :additional_document_validation_request

    drop_table :other_change_validation_requests
    drop_table :description_change_validation_requests
    drop_table :red_line_boundary_change_validation_requests
    drop_table :replacement_document_validation_requests
    drop_table :additional_document_validation_requests
  end

  def down
    rename_column :validation_requests, :type, :requestable_type

    change_table :validation_requests do |t|
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

    create_table :replacement_document_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :old_document, foreign_key: {to_table: :documents}
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

    add_reference :documents, :additional_document_validation_request, foreign_key: true

    validation_request = Class.new(ActiveRecord::Base) do
      self.table_name = "validation_requests"
      store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]
    end

    validation_request.all.where(requestable_type: "AdditionalDocumentValidationRequest").find_each do |request|
      new_request = AdditionalDocumentValidationRequest.create!(
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

      Document.find_by(owner_id: request.id, owner_type: "ValidationRequest")&.update(additional_document_validation_request_id: new_request.id)

      request.update(
        requestable_id: new_request.id,
        requestable_type: "AdditionalDocumentValidationRequest"
      )
    end

    add_reference :documents, :replacement_document_validation_request, foreign_key: true

    validation_request.all.where(requestable_type: "ReplacementDocumentValidationRequest").find_each do |request|
      document = Document.find_by(owner_id: request.id, owner_type: "ValidationRequest")
      
      new_request = ReplacementDocumentValidationRequest.create!(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        old_document_id: request.old_document_id,
        new_document_id: document&.id,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        planning_application_id: request.planning_application_id
      )

      document&.update(replacement_document_validation_request_id: new_request.id)

      request.update(
        requestable_id: new_request.id,
        requestable_type: "ReplacementDocumentValidationRequest"
      )
    end

    validation_request.all.where(requestable_type: "RedLineBoundaryChangeValidationRequest").find_each do |request|
      new_request = RedLineBoundaryChangeValidationRequest.create!(
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
        requestable_type: "RedLineBoundaryChangeValidationRequest"
      )
    end

    validation_request.all.where(requestable_type: "DescriptionChangeValidationRequest").find_each do |request|
      new_request = DescriptionChangeValidationRequest.create!(
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
        requestable_type: "DescriptionChangeValidationRequest"
      )
    end

    validation_request.all.where(requestable_type: "OtherChangeValidationRequest").find_each do |request|
      new_request = OtherChangeValidationRequest.create!(
        state: request.state,
        user_id: request.user_id,
        post_validation: request.post_validation,
        notified_at: request.notified_at,
        cancelled_at: request.cancelled_at,
        cancel_reason: request.cancel_reason,
        sequence: request.sequence,
        fee_item: false,
        summary: request.reason,
        suggestion: request.specific_attributes["suggestion"],
        planning_application_id: request.planning_application_id
      )

      request.update(
        requestable_id: new_request.id,
        requestable_type: "OtherChangeValidationRequest"
      )
    end

    validation_request.all.where(requestable_type: "FeeChangeValidationRequest").find_each do |request|
      new_request = OtherChangeValidationRequest.create!(
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
        requestable_type: "OtherChangeValidationRequest"
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
      t.remove :sequence
      t.remove :specific_attributes
    end
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
