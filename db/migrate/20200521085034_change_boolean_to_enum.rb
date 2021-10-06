# frozen_string_literal: true

class ChangeBooleanToEnum < ActiveRecord::Migration[6.0]
  def up
    remove_column :policy_evaluations, :requirements_met
    add_column :policy_evaluations, :status, :integer, default: 0, null: false
  end

  def down
    add_column :policy_evaluations, :requirements_met, :boolean, default: false, null: false
    remove_column :policy_evaluations, :status
  end
end
