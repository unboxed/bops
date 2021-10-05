# frozen_string_literal: true

class AddPaymentReferenceToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :payment_reference, :string
  end
end
