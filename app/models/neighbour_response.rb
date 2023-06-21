# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour

  validates :name, :response, :received_at, presence: true

  enum(summary_tag: { supportive: "supportive", neutral: "neutral", objection: "objection" })
end
