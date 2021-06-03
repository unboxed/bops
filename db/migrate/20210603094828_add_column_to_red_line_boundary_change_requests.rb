class AddColumnToRedLineBoundaryChangeRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :red_line_boundary_change_requests, :approved, :boolean
  end
end
