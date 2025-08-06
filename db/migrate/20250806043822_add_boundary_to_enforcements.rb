# frozen_string_literal: true

class AddBoundaryToEnforcements < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :boundary, :geometry_collection, geographic: true
  end
end
