# frozen_string_literal: true

class Policy < ApplicationRecord
  belongs_to :policy_class
  has_one :comment, as: :commentable, dependent: :destroy

  default_scope { order(:section) }

  accepts_nested_attributes_for(
    :comment,
    update_only: true,
    reject_if: proc { |attributes| attributes[:text].blank? }
  )

  validates :description, :status, presence: true

  enum(
    status: { complies: 0, does_not_comply: 1, to_be_determined: 2 },
    _default: :to_be_determined
  )

  statuses.each_key { |status| scope status, -> { where(status: status) } }

  scope :with_a_comment, -> { joins(:comment) }

  def self.commented_or_does_not_comply
    (does_not_comply | with_a_comment).sort_by(&:section)
  end

  def existing_or_new_comment
    comment || build_comment
  end
end
