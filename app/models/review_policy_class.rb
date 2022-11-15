class ReviewPolicyClass < ApplicationRecord
  belongs_to :policy_class, optional: true

  validates :mark, :status, presence: true

  enum mark: { not_marked: 0, accept: 1, return_to_officer: 2 }
  enum status: { not_checked_yet: 0, complete: 1 }, _default: :not_checked_yet, _prefix: true
end
