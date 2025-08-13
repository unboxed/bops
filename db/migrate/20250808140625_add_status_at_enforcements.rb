# frozen_string_literal: true

class AddStatusAtEnforcements < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :not_started_at, :datetime
    add_column :enforcements, :under_investigation_at, :datetime
    add_column :enforcements, :closed_at, :datetime
  end
end
