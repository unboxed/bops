# frozen_string_literal: true

class AddUniqueIndexToApiUseOnNameAndToken < ActiveRecord::Migration[6.1]
  def change
    change_table :api_users, bulk: true do |t|
      t.change_default(:name, from: "", to: nil)
      t.change_default(:token, from: "", to: nil)
    end

    add_index :api_users, :name, unique: true
    add_index :api_users, :token, unique: true
  end
end
