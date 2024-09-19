# frozen_string_literal: true

class PlanningApplicationPolicySection < ApplicationRecord
  belongs_to :planning_application
  belongs_to :policy_section

  has_many(
    :comments,
    -> { order(:created_at) },
    as: :commentable,
    inverse_of: :commentable,
    dependent: :destroy
  )

  accepts_nested_attributes_for(
    :comments,
    reject_if: :reject_comment?
  )

  validates :status, presence: true

  enum(
    status: {
      complies: "complies",
      does_not_comply: "does_not_comply",
      to_be_determined: "to_be_determined"
    },
    _default: :to_be_determined
  )

  def last_comment
    @last_comment ||= persisted_comments.last
  end

  def previous_comments
    persisted_comments - [last_comment]
  end

  private

  def persisted_comments
    comments.select(&:persisted?)
  end

  def reject_comment?(attributes)
    attributes[:text].blank? || attributes[:text] == last_comment&.text
  end
end
