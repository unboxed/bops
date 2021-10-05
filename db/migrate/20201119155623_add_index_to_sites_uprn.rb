# frozen_string_literal: true

class AddIndexToSitesUprn < ActiveRecord::Migration[6.0]
  def change
    add_index :sites, :uprn, unique: true
  end
end
