# frozen_string_literal: true

class Policy < ApplicationRecord
  belongs_to :policy_class

  has_many(
    :comments,
    -> { order(:created_at) },
    as: :commentable,
    inverse_of: :commentable,
    dependent: :destroy
  )

  default_scope { order(:section) }

  accepts_nested_attributes_for(
    :comments,
    reject_if: :reject_comment?
  )

  validates :description, :status, presence: true

  enum(
    status: { complies: 0, does_not_comply: 1, to_be_determined: 2 },
    _default: :to_be_determined
  )

  statuses.each_key { |status| scope status, -> { where(status:) } }

  def self.with_a_comment
    all.select(&:comment)
  end

  def self.commented_or_does_not_comply
    (does_not_comply | with_a_comment).sort_by(&:section)
  end

  def comment
    last_comment unless last_comment&.deleted?
  end

  def previous_comments
    persisted_comments - [comment]
  end

  private

  def last_comment
    @last_comment ||= persisted_comments.last
  end

  def reject_comment?(attributes)
    attributes[:text] == comment&.text ||
      (comment.blank? && attributes[:text].blank?)
  end

  def persisted_comments
    comments.select(&:persisted?)
  end
end
