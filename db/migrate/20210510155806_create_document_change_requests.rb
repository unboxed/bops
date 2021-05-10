class CreateDocumentChangeRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :document_change_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.string :state, default: "open", null: false
      t.boolean :approved
      t.string :rejection_reason

      t.timestamps
    end
  end
end
