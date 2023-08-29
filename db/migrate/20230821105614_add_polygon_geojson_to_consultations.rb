# frozen_string_literal: true

class AddPolygonGeojsonToConsultations < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :polygon_geojson, :json
  end
end
