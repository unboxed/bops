# frozen_string_literal: true

class DropPlanningApplicationIdFromConditions < ActiveRecord::Migration[7.0]
  def change
    remove_reference :conditions, :planning_application, index: true
  end
end
