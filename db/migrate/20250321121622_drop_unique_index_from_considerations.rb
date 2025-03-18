# frozen_string_literal: true

class DropUniqueIndexFromConsiderations < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      remove_index :considerations, name: "ix_considerations_on_consideration_set_id__policy_area", algorithm: :concurrently, if_exists: true
    end
  end
end
