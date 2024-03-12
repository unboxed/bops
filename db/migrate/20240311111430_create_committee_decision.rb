# frozen_string_literal: true

class CreateCommitteeDecision < ActiveRecord::Migration[7.1]
  def change
    create_table :committee_decisions do |t|
      t.references :planning_application, index: {unique: true}
      t.boolean :recommend, null: false, default: false
      t.jsonb :reasons, array: true
      t.datetime :date_of_committee
      t.timestamps
    end
  end
end
