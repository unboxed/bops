# frozen_string_literal: true

class CreatePlanningApplicationConstraintsQuery < ActiveRecord::Migration[7.0]
  def change
    create_table :planning_application_constraints_queries do |t|
      t.json :geojson, null: false
      t.text :wkt, null: false
      t.string :planx_query, null: false
      t.string :planning_data_query, null: false
      t.references :planning_application, foreign_key: true

      t.timestamps
    end
  end
end
