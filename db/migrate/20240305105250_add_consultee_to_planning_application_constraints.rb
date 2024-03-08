# frozen_string_literal: true

class AddConsulteeToPlanningApplicationConstraints < ActiveRecord::Migration[7.1]
  def change
    add_reference :planning_application_constraints, :consultee, null: true, foreign_key: true
  end
end
