# frozen_string_literal: true

class AddPaymentAmountToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :payment_amount, :integer
  end
end
