# frozen_string_literal: true

class RemoveUniqueIndexOnInformativeText < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :informatives, [:text, :informative_set_id], unique: true, algorithm: :concurrently, if_exists: true
  end
end
