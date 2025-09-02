# frozen_string_literal: true

class NeighbourResponse < ApplicationRecord
  belongs_to :neighbour
  belongs_to :redacted_by, class_name: "User", optional: true

  validates_associated :neighbour

  has_many :documents, as: :owner, dependent: :destroy

  attr_readonly :response

  validates :name, :response, :summary_tag, :received_at, presence: true

  enum :summary_tag, %i[supportive neutral objection].index_with(&:to_s)

  scope :redacted, -> { where.not(redacted_response: "") }
  scope :with_tags, -> { where.not(tags: []) }
  scope :without_tags, -> { where(tags: []) }

  TAGS = %i[use privacy light access noise traffic design other].freeze

  summary_tags.each do |tag|
    scope :"#{tag}", -> { where(tags: [tag]) }
  end

  before_save do
    self.tags = tags.compact_blank! if tags.any?
  end

  def comment
    redacted_response.presence || response
  end
end
