# frozen_string_literal: true

class UseJsonbColumnType < ActiveRecord::Migration[7.0]
  def up
    change_table :consultations do |t|
      t.change :polygon_geojson, :jsonb
    end

    change_table :neighbour_letters do |t|
      t.change :notify_response, :jsonb
    end

    change_table :planning_application_constraints_queries do |t|
      t.change :geojson, :jsonb
    end

    change_table :planning_applications do |t|
      t.change :boundary_geojson, :jsonb
    end

    change_table :red_line_boundary_change_validation_requests, bulk: true do |t|
      t.change :new_geojson, :jsonb
      t.change :original_geojson, :jsonb
    end
  end

  def down
    change_table :consultations do |t|
      t.change :polygon_geojson, :json
    end

    change_table :neighbour_letters do |t|
      t.change :notify_response, :json
    end

    change_table :planning_application_constraints_queries do |t|
      t.change :geojson, :json
    end

    change_table :planning_applications do |t|
      t.change :boundary_geojson, :json
    end

    change_table :red_line_boundary_change_validation_requests, bulk: true do |t|
      t.change :new_geojson, :json
      t.change :original_geojson, :json
    end
  end
end
