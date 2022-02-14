# frozen_string_literal: true

class AddUpdatedAddressOrBoundaryGeojsonToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :updated_address_or_boundary_geojson, :boolean, default: false
  end
end
