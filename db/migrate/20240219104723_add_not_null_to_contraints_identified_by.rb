# frozen_string_literal: true

class AddNotNullToContraintsIdentifiedBy < ActiveRecord::Migration[7.1]
  class PlanningApplicationConstraint < ActiveRecord::Base; end

  def change
    up_only do
      PlanningApplicationConstraint.where(identified_by: nil).update_all(identified_by: "BOPS")
    end

    change_column_null(:planning_application_constraints, :identified_by, false)
  end
end
