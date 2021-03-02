# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :file, dependent: :destroy

  enum archive_reason: { scale: 0,
                         design: 1,
                         dimensions: 2,
                         other: 3 }
  TAGS = %w[
    Front
    Rear
    Side
    Roof
    Floor
    Site
    Plan
    Elevation
    Section
    Proposed
    Existing
  ].freeze

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"].freeze

  validate :tag_values_permitted
  validate :file_content_type_permitted
  validate :file_attached
  validate :numbered

  scope :active, -> { where(archived_at: nil) }
  scope :referenced, -> { where(referenced_in_decision_notice: true) }
  scope :publishable, -> { where(publishable: true) }

  scope :for_publication, -> { active.publishable }
  scope :for_display, -> { active.referenced }

  def name
    file.filename if file.attached?
  end

  def archived?
    archived_at.present?
  end

  def referenced_in_decision_notice?
    referenced_in_decision_notice == true
  end

  def archive(archive_reason)
    unless archived?
      update!(archive_reason: archive_reason,
              archived_at: Time.zone.now)
    end
  end

  def numbers=(nums)
    super(nums.split(",").select(&:present?).map(&:strip)) if nums
  end

  def numbers
    super.join(", ")
  end

  def published?
    self.class.for_publication.where(id: id).any?
  end

private

  def tag_values_permitted
    unless (tags - Document::TAGS).empty?
      errors.add(:tags, :unpermitted_tags)
    end
  end

  def file_content_type_permitted
    return unless file.attached? && file.blob&.content_type

    unless PERMITTED_CONTENT_TYPES.include? file.blob.content_type
      errors.add(:file, :unsupported_file_type)
    end
  end

  def file_attached
    unless file.attached?
      errors.add(:file, :missing_file)
    end
  end

  def numbered
    if referenced_in_decision_notice? && numbers.empty?
      errors.add(:numbers, :missing_number)
    end
  end
end
