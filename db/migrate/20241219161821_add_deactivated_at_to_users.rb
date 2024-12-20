# frozen_string_literal: true

class AddDeactivatedAtToUsers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :users, :deactivated_at, :datetime
    add_index :users, :deactivated_at, algorithm: :concurrently
  end
end
