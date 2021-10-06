# frozen_string_literal: true

class AddAwaitingCorrectionAtOnPlanningApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :awaiting_correction_at, :datetime, null: true
  end
end
