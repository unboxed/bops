# frozen_string_literal: true

class AddInvalidPaymentAmountToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :invalid_payment_amount, :decimal, precision: 10, scale: 2
  end
end
