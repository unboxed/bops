# frozen_string_literal: true

class ChangePaymentAmountToDecimal < ActiveRecord::Migration[6.1]
  class PlanningApplication < ApplicationRecord; end

  def up
    change_column :planning_applications, :payment_amount, :decimal, precision: 10, scale: 2

    PlanningApplication.find_each do |planning_application|
      payment_amount = planning_application.payment_amount

      unless payment_amount.nil? || payment_amount.zero?
        payment_amount_in_pounds = payment_amount.to_f / 100

        planning_application.update!(payment_amount: payment_amount_in_pounds)
      end
    end
  end

  def down
    PlanningApplication.find_each do |planning_application|
      payment_amount = planning_application.payment_amount

      unless payment_amount.nil? || payment_amount.zero?
        payment_amount_in_pence = payment_amount.to_f * 100

        planning_application.update!(payment_amount: payment_amount_in_pence)
      end
    end

    change_column :planning_applications, :payment_amount, :integer
  end
end
