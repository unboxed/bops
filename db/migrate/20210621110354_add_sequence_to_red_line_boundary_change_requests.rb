# frozen_string_literal: true

class AddSequenceToRedLineBoundaryChangeRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :red_line_boundary_change_requests, :sequence, :integer
  end
end
