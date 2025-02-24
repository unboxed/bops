# frozen_string_literal: true

class CreateLocalAuthorityApplicationTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :local_authority_application_types do |t|
      t.references :local_authority, null: false, foreign_key: true
      t.references :application_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :local_authority_application_types, [:local_authority_id, :application_type_id], unique: true, name: "index_local_authority_application_types"
  end
end
