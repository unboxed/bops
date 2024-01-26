# frozen_string_literal: true

class AddNeighbourBoundaryGeojsonToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :neighbour_boundary_geojson, :jsonb
  end
end
