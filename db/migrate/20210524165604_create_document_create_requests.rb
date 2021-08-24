class CreateDocumentCreateRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :document_create_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :new_document, foreign_key: { to_table: :documents }
      t.string :state, default: "open", null: false
      t.string :document_request_type
      t.string :document_request_reason

      t.timestamps
    end
  end
end
