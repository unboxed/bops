# frozen_string_literal: true

class AddColumnsToValidationRequest < ActiveRecord::Migration[7.0]
  def up
    change_table :validation_requests, bulk: true do |t|
      t.string :state, null: false
      t.references :user, null: false
      t.boolean :post_validation, default: false, null: false
      t.boolean :applicant_approved
      t.text :reason
      t.string :applicant_rejection_reason
      t.text :applicant_response
      t.datetime :notified_at
      t.datetime :cancelled_at
      t.text :cancel_reason
      t.boolean :auto_closed
      t.datetime :auto_closed_at
      t.references :old_document, foreign_key: {to_table: :documents}
      t.references :new_document, foreign_key: {to_table: :documents}
      t.integer :sequence
      t.jsonb :specific_attributes
    end

    rename_column :validation_requests, :requestable_type, :request_type
    change_column :validation_requests, :requestable_id, :bigint, null: true
  end

  def down
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
    end

    rename_column :validation_requests, :request_type, :requestable_type
    change_column :validation_requests, :requestable_id, :bigint, null: false
  end
end
