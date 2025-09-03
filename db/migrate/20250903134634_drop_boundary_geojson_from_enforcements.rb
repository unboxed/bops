# frozen_string_literal: true

class DropBoundaryGeojsonFromEnforcements < ActiveRecord::Migration[7.2]
  def change
    safety_assured { remove_column :enforcements, :boundary_geojson, :geometry_collection }
  end
end
