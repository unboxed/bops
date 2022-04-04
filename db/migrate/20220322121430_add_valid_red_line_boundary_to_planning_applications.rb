# frozen_string_literal: true

class AddValidRedLineBoundaryToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :valid_red_line_boundary, :boolean
  end
end
