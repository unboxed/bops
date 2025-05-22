# frozen_string_literal: true

class AddPermissionsToApiUser < ActiveRecord::Migration[7.2]
  def change
    add_column :api_users, :permissions, :string, array: true
  end
end
