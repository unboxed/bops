# frozen_string_literal: true

class AddLastUsedAtToApiUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :api_users, :last_used_at, :datetime
  end
end
