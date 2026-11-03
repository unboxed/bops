# frozen_string_literal: true

class AddClosureRejectionReasonToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :closure_rejection_reason, :string
  end
end
