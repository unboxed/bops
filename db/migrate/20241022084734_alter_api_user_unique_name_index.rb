# frozen_string_literal: true

class AlterApiUserUniqueNameIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        remove_index :api_users, [:local_authority_id, :name], unique: true, algorithm: :concurrently
        add_index :api_users, [:local_authority_id, :name], unique: true, where: "revoked_at IS NULL", algorithm: :concurrently
      end

      dir.down do
        remove_index :api_users, [:local_authority_id, :name], unique: true, where: "revoked_at IS NULL", algorithm: :concurrently
        add_index :api_users, [:local_authority_id, :name], unique: true, algorithm: :concurrently
      end
    end
  end
end
