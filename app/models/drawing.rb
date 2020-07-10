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

  def archived?
     archived_at.present?
   end

  def archive(archive_reason)
    update(archive_reason: archive_reason,
           archived_at: Time.current) unless archived?
  end
end
