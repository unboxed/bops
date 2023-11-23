# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToProposalMeasurements < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :proposal_measurements, :planning_applications
  end
end
