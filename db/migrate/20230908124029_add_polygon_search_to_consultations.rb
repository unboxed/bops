# frozen_string_literal: true

class AddPolygonSearchToConsultations < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :polygon_search, :geometry_collection, geographic: true
  end
end
