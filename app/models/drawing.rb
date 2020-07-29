# frozen_string_literal: true

class Drawing < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :plan

  enum archive_reason: { scale: 0, design: 1,
                         dimensions: 2, other: 3 }

  ORIENTATION_TAGS = [
    "front elevation",
    "side elevation",
    "floor plan",
    "section"
  ].freeze

  STATE_TAGS = [ "proposed", "existing" ].freeze

  TAGS = ORIENTATION_TAGS.product(STATE_TAGS).map do |tags|
    [tags.first, tags.second].join(" - ")
  end.freeze

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"]

  validate :plan_content_type_permitted

  def name
    plan.filename if plan.attached?
  end

  def archived?
     archived_at.present?
   end

  def archive(archive_reason)
    update(archive_reason: archive_reason,
           archived_at: Time.current) unless archived?
  end

  private

  def plan_content_type_permitted
    return unless plan.attached? && plan.blob&.content_type

    unless PERMITTED_CONTENT_TYPES.include? plan.blob.content_type
      errors.add(:plan, :unsupported_file_type)
    end
  end
end
