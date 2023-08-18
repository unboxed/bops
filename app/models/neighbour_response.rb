# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour

  validates :name, :response, :received_at, presence: true

  enum(summary_tag: { supportive: "supportive", neutral: "neutral", objection: "objection" })

  scope :redacted, -> { where.not(redacted_response: "") }

  TAGS = %i[design new_use privacy disabled_access noise traffic other]

  summary_tags.each do |tag|
    scope :"#{tag}", -> { where(tag:) }
  end

  before_save do
    self.tags = self.tags.reject!(&:blank?)
  end

  def truncated_comment
    comment = redacted_response.present? ? redacted_response : response
    comment.truncate(100, separator: " ")
  end

  def comment
    redacted_response.present? ? redacted_response : response
  end
end
