class CreateRedLineBoundaryChangeRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :red_line_boundary_change_requests do |t|
      t.integer :planning_application_id, null: false
      t.integer :user_id, null: false
      t.string :state, default: "open", null: false
      t.string :new_geojson
      t.string :reason
      t.string :rejection_reason
      t.boolean :approved

      t.timestamps
    end
  end
end
