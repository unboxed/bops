# frozen_string_literal: true

class AddConsultationRequiredToPlanningApplicationConstraint < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_application_constraints, :consultation_required, :boolean

    up_only do
      PlanningApplicationConstraint.find_each do |constraint|
        constraint.update!(consultation_required: true)
      end

      change_column_default :planning_application_constraints, :consultation_required, true
      change_column_null :planning_application_constraints, :consultation_required, false
    end
  end
end
