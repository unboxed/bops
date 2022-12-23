# frozen_string_literal: true

class ReviewPolicyClass < ApplicationRecord
  belongs_to :policy_class, optional: true

  enum mark: { not_marked: 0, accept: 1, return_to_officer_with_comment: 2 }
  enum status: { not_checked_yet: 0, complete: 1, updated: 2 }, _default: :not_checked_yet, _prefix: true

  validates :mark, presence: true
  validates :comment, presence: true, if: :return_to_officer_with_comment?
  validate :recommendation_not_accepted

  def last_recommendation_accepted?
    policy_class&.planning_application&.last_recommendation_accepted?
  end

  private

  def recommendation_not_accepted
    return unless last_recommendation_accepted?

    errors.add(:base, :recommendation_accepted)
  end
end
