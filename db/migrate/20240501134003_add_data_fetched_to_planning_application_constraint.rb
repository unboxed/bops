# frozen_string_literal: true

class AddDataFetchedToPlanningApplicationConstraint < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_application_constraints, :status, :string, default: "pending", null: false

    PlanningApplicationConstraint.find_each do |constraint|
      status = constraint.data.blank? ? "pending" : "success"

      constraint.update!(status:)
    end
  end
end
