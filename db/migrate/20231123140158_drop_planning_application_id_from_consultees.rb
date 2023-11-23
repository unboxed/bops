# frozen_string_literal: true

class DropPlanningApplicationIdFromConsultees < ActiveRecord::Migration[7.0]
  def change
    remove_reference :consultees, :planning_application, index: true
  end
end
