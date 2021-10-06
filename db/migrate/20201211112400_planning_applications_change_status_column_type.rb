# frozen_string_literal: true

class PlanningApplicationsChangeStatusColumnType < ActiveRecord::Migration[6.0]
  def change
    change_column(:planning_applications, :status, :string)
  end
end
