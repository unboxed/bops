# frozen_string_literal: true

class LocalPolicyArea < ApplicationRecord
  belongs_to :local_policy

  validates :assessment, :policies, :area, presence: true, if: :completed?

  attr_reader :policy

  def enabled?
    enabled == true
  end

  private

  def completed?
    return if local_policy.reviews.none?

    local_policy.current_review&.status == "complete" || local_policy.reviews.last.status == "complete"
  end
end
