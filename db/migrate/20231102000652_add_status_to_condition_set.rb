# frozen_string_literal: true

class AddStatusToConditionSet < ActiveRecord::Migration[7.0]
  def change
    add_column :condition_sets, :status, :string, default: "not_started", null: false
  end
end
