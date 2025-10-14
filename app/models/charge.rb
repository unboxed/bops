# frozen_string_literal: true

class Charge < ApplicationRecord
  belongs_to :planning_application
  has_one :payment, dependent: :destroy

  accepts_nested_attributes_for :payment, allow_destroy: true, reject_if: :all_blank

  validates :description, :amount, presence: true
end
