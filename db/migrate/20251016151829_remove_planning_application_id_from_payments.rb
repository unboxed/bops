# frozen_string_literal: true

class RemovePlanningApplicationIdFromPayments < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_reference :payments, :planning_application, null: false, foreign_key: true }
  end
end
