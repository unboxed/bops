class RenameRedLineBoundaryChangeRequests < ActiveRecord::Migration[6.1]
  def change
    rename_table :red_line_boundary_change_requests, :red_line_boundary_change_validation_requests
  end
end
