# frozen_string_literal: true

class CreateEvidenceGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :evidence_groups do |t|
      t.integer :tag
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :missing_evidence
      t.string :missing_evidence_entry
      t.string :applicant_comment

      t.references :immunity_detail

      t.timestamps
    end

    add_reference :documents, :evidence_group, references: :evidence_groups,
      foreign_key: {to_table: :evidence_groups}, null: true
  end
end
