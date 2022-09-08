# frozen_string_literal: true

class Policy < ApplicationRecord
  belongs_to :policy_class
  has_one :comment, dependent: :destroy

  accepts_nested_attributes_for(
    :comment,
    update_only: true,
    reject_if: proc { |attributes| attributes[:text].blank? }
  )

  validates :description, :section, :status, presence: true

  enum(
    status: { complies: 0, does_not_comply: 1, to_be_determined: 2 },
    _default: :to_be_determined
  )

  statuses.each_key { |status| scope status, -> { where(status: status) } }

  def existing_or_new_comment
    comment || build_comment
  end
end
