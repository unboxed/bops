# frozen_string_literal: true

class Consultee
  class Response < ApplicationRecord
    belongs_to :consultee
    belongs_to :redacted_by, class_name: "User", optional: true

    has_many :documents, dependent: :destroy

    attr_readonly :response

    validates :name, :response, :received_at, presence: true

    scope :redacted, -> { where.not(redacted_response: "") }

    def truncated_comment
      comment.truncate(100, separator: " ")
    end

    def comment
      (redacted_response.presence || response)
    end
  end
end
