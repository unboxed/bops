# frozen_string_literal: true

class AddConfigIdAndLocalAuthorityIdToApplicationTypes < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_reference :application_types, :config, foreign_key: {to_table: :application_type_configs}

      add_reference :application_types, :local_authority, foreign_key: true

      remove_index :application_types, :code, unique: true, where: "((status)::text <> 'retired'::text)"
      remove_index :application_types, :suffix, unique: true

      add_index :application_types, [:local_authority_id, :code], unique: true, where: "((status)::text <> 'retired'::text)"
      add_index :application_types, [:local_authority_id, :suffix], unique: true
      add_index :application_types, [:local_authority_id, :config_id], unique: true
    end
  end
end
