# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour
  belongs_to :redacted_by, class_name: "User", optional: true

  validates_associated :neighbour

  has_many :documents, dependent: :destroy

  attr_readonly :response

  validates :name, :response, :summary_tag, :received_at, presence: true

  enum(summary_tag: {supportive: "supportive", neutral: "neutral", objection: "objection"})

  scope :redacted, -> { where.not(redacted_response: "") }
  scope :with_tags, -> { where.not(tags: []) }
  scope :without_tags, -> { where(tags: []) }

  TAGS = %i[design new_use privacy disabled_access noise traffic other].freeze

  summary_tags.each do |tag|
    scope :"#{tag}", -> { where(tags: [tag]) }
  end

  before_save do
    self.tags = tags.compact_blank! if tags.any?
  end

  def truncated_comment
    comment.truncate(100, separator: " ")
  end

  def comment
    redacted_response.presence || response
  end
end
