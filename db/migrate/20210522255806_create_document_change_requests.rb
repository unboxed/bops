# frozen_string_literal: true

class CreateDocumentChangeRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :document_change_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :old_document, null: false, foreign_key: {to_table: :documents}
      t.references :new_document, foreign_key: {to_table: :documents}
      t.string :state, default: "open", null: false

      t.timestamps
    end
  end
end
