# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour
  belongs_to :consultation
  belongs_to :redacted_by, class_name: "User", optional: true

  has_many :documents, dependent: :destroy

  attr_readonly :comment

  validates :name, :response, :summary_tag, :received_at, presence: true

  enum(summary_tag: { supportive: "supportive", neutral: "neutral", objection: "objection" })

  scope :redacted, -> { where.not(redacted_response: "") }

  TAGS = %i[design new_use privacy disabled_access noise traffic other].freeze

  summary_tags.each do |tag|
    scope :"#{tag}", -> { where(tag:) }
  end

  before_save do
    self.tags = tags.compact_blank! if tags.any?
  end

  def truncated_comment
    comment.truncate(100, separator: " ")
  end

  def comment
    (redacted_response.presence || response)
  end
end
