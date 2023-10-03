# frozen_string_literal: true

class Consideration < ApplicationRecord
  belongs_to :policy_area

  validates_presence_of :assessment, :policies, :area, if: :completed?

  attr_reader :policy

  private

  def completed?
    policy_area.status == "complete"
  end
end
