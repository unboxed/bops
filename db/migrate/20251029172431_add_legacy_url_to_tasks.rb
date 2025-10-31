# frozen_string_literal: true

class AddLegacyUrlToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :legacy_url, :string
  end
end
