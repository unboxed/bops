# frozen_string_literal: true

class DropNullOnGeojsonAndWktAtPlanningApplicationConstraintsQueries < ActiveRecord::Migration[7.0]
  def change
    change_column_null :planning_application_constraints_queries, :geojson, true
    change_column_null :planning_application_constraints_queries, :wkt, true
  end
end
