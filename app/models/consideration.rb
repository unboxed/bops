# frozen_string_literal: true

class Consideration < ApplicationRecord
  belongs_to :policy_area

  validates :assessment, :policies, :area, presence: { if: :completed? }

  attr_reader :policy

  private

  def completed?
    policy_area.status == "complete"
  end
end
