# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role, :integer, default: 0
    add_column :users, :name, :string
  end
end
