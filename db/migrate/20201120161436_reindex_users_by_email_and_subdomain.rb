# frozen_string_literal: true

class ReindexUsersByEmailAndSubdomain < ActiveRecord::Migration[6.0]
  def up
    remove_index :users, :email
    add_index :users, %i[email local_authority_id], unique: true
  end

  def down
    remove_index :users, %i[email local_authority_id]
    add_index :users, :email, unique: true
  end
end
