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

  scope :has_proposed_tag, -> {
    where("tags ?| array[:proposed_tag_array]",
      proposed_tag_array: Drawing::PROPOSED_TAGS)
  }
  scope :has_empty_numbers, -> { where("numbers = '[]'") }
  scope :active, -> { where(archived_at: nil) }

  scope :for_publication, -> { active.has_proposed_tag }

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

  def numbers=(nums)
    super(nums.split(",").select(&:present?).map(&:strip)) if nums
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
