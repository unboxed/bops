# frozen_string_literal: true

class AddUrgencyReasonToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :urgency_reason, :string
  end
end
