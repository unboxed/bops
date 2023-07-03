# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour

  validates :name, :response, :received_at, presence: true

  scope :redacted, -> { where.not(redacted_response: "") }

  enum(summary_tag: { supportive: "supportive", neutral: "neutral", objection: "objection" })
end
