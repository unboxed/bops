# frozen_string_literal: true

class AddInCommitteeAtToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :in_committee_at, :datetime
  end
end
