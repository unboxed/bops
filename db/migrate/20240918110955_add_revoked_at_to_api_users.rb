# frozen_string_literal: true

class AddRevokedAtToApiUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :api_users, :revoked_at, :datetime, null: true
    add_index :api_users, :revoked_at, algorithm: :concurrently
  end
end
