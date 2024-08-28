# frozen_string_literal: true

class AddTitleToPolicySections < ActiveRecord::Migration[7.1]
  def change
    add_column :policy_sections, :title, :string
  end
end
