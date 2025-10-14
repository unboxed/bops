# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :charge
  delegate :planning_application, to: :charge

  validates :payment_date, :payment_type, :reference, presence: true
  validates :amount, presence: true, numericality: {greater_than: 0}
end
