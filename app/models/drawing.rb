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

  neil = "woo"

  PROPOSED_TAGS = ORIENTATION_TAGS.product(["proposed"]).map do |tags|
    [tags.first, tags.second].join(" - ")
  end.freeze

  EXISTING_TAGS = ORIENTATION_TAGS.product(["existing"]).map do |tags|
    [tags.first, tags.second].join(" - ")
  end.freeze

  TAGS = (PROPOSED_TAGS + EXISTING_TAGS).freeze

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"]

  validate :tag_values_permitted
  validate :plan_content_type_permitted

  scope :has_proposed_tag, -> { where("tags ?| array[#{Drawing.proposed_tag_query}]") }

  def self.proposed_tag_query
    Drawing::PROPOSED_TAGS.map { |tag| "'#{tag}'" }.join(",")
  end

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

  # "123, 234, 345" Drawing numbers

  def numbers=(nums)
    super(nums.split(",").map(&:strip))
  end

  def numbers
    super.join(", ")
  end

  private

  def tag_values_permitted
    return if tags.empty?

    unless (tags - Drawing::TAGS).empty?
      errors.add(:tags, :unpermitted_tags)
    end
  end

  def plan_content_type_permitted
    return unless plan.attached? && plan.blob&.content_type

    unless PERMITTED_CONTENT_TYPES.include? plan.blob.content_type
      errors.add(:plan, :unsupported_file_type)
    end
  end
end
