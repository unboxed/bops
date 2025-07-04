# frozen_string_literal: true

class AddDatesToEnforcement < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :received_at, :datetime, null: false
    add_column :enforcements, :started_at, :datetime
    add_column :enforcements, :notice_served_at, :datetime
  end
end
