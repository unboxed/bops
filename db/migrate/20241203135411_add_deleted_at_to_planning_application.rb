# frozen_string_literal: true

class AddDeletedAtToPlanningApplication < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :planning_applications, :deleted_at, :datetime
    add_index :planning_applications, :deleted_at, algorithm: :concurrently
  end
end
