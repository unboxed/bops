# frozen_string_literal: true

class AddUprnToSites < ActiveRecord::Migration[6.0]
  def change
    add_column :sites, :uprn, :string, null: true
  end
end
