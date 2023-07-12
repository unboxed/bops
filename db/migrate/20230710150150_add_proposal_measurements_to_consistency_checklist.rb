# frozen_string_literal: true

class AddProposalMeasurementsToConsistencyChecklist < ActiveRecord::Migration[7.0]
  def change
    add_column :consistency_checklists, :proposal_measurements_match_documents, :integer, default: 0, null: false
  end
end
