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

  scope :by_id, -> { order(:id) }

  accepts_nested_attributes_for(
    :comments,
    reject_if: :reject_comment?
  )

  validates :status, :description, presence: true

  before_validation :set_description, on: :create

  enum :status,
    %i[complies does_not_comply to_be_determined].index_with(&:to_s),
    default: :to_be_determined

  delegate :section, :title, to: :policy_section
  delegate :policy_class, to: :policy_section

  def set_description
    self.description ||= policy_section.description
  end

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
