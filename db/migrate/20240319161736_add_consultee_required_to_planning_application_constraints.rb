# frozen_string_literal: true

class AddConsulteeRequiredToPlanningApplicationConstraints < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_application_constraints, :consultee_required, :boolean, default: true, null: false
  end
end
