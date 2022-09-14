# frozen_string_literal: true

class CreateConsistencyChecklists < ActiveRecord::Migration[6.1]
  def change
    create_table :consistency_checklists do |t|
      t.integer :status, null: false
      t.integer :description_matches_documents, null: false
      t.integer :documents_consistent, null: false
      t.integer :proposal_details_match_documents, null: false
      t.text :proposal_details_match_documents_comment
      t.references :planning_application
      t.timestamps
    end
  end
end
