# frozen_string_literal: true

class AddClosedReasonToEnforcement < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :closed_reason, :string, null: true
    add_column :enforcements, :closed_detail, :string, null: true
  end
end
