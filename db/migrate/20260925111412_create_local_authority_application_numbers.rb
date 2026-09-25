# frozen_string_literal: true

class CreateLocalAuthorityApplicationNumbers < ActiveRecord::Migration[8.1]
  def change
    create_table :local_authority_application_numbers do |t|
      t.references :local_authority, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :application_number, null: false

      t.timestamps
    end

    add_index :local_authority_application_numbers, [:local_authority_id, :year], unique: true
  end
end
