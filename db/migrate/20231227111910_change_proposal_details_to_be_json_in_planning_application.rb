# frozen_string_literal: true

class ChangeProposalDetailsToBeJsonInPlanningApplication < ActiveRecord::Migration[7.0]
  def up
    change_column :planning_applications, :proposal_details, :json
  end

  def down
    change_column :planning_applications, :proposal_details, :jsonb
  end
end
