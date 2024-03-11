# frozen_string_literal: true

class CreateDocumentChecklists < ActiveRecord::Migration[7.1]
  def change
    create_table :document_checklists do |t|
      t.references :planning_application, null: false, foreign_key: true, index: true
      t.timestamps
    end

    create_table :document_checklist_items do |t|
      t.string :category, null: false
      t.jsonb :tags, default: [], null: false
      t.string :description, null: false
      t.references :document_checklist, null: false
      t.timestamps
    end

    add_reference :documents, :document_checklist_items, foreign_key: true, index: true
  end
end
