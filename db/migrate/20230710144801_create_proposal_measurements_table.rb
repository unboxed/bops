# frozen_string_literal: true

class CreateProposalMeasurementsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :proposal_measurements do |t|
      t.references :planning_application
      t.float :eaves_height
      t.float :depth
      t.float :max_height
      t.timestamps
    end
  end
end
