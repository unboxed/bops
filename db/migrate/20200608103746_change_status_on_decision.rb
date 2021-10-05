# frozen_string_literal: true

class ChangeStatusOnDecision < ActiveRecord::Migration[6.0]
  def up
    change_column :decisions, :status, :integer, default: nil, null: true
  end

  def down
    change_column :decisions, :status, :integer, default: 0, null: false
  end
end
