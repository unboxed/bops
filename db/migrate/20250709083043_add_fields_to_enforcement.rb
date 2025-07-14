# frozen_string_literal: true

class AddFieldsToEnforcement < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :proposal_details, :jsonb
    add_column :enforcements, :uprn, :string
    add_column :enforcements, :boundary_geojson, :geometry_collection, geographic: true
    add_column :enforcements, :lonlat, :st_point, geographic: true
  end
end
