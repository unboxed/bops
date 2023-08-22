# frozen_string_literal: true

class AddPolygonColourToConsultations < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :polygon_colour, :string, default: "#d870fc", null: false
  end
end
