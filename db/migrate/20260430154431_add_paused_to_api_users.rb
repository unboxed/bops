# frozen_string_literal: true

class AddPausedToApiUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :api_users, :paused, :boolean, default: false, null: false
  end
end
