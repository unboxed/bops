# frozen_string_literal: true

class Refund < ApplicationRecord
  belongs_to :planning_application

  validates :amount, :date, :payment_type, :reason, presence: true
end
