# frozen_string_literal: true

class Consultee
  class Response < ApplicationRecord
    belongs_to :consultee
    belongs_to :redacted_by, class_name: "User", optional: true

    has_many :documents, as: :owner, dependent: :destroy

    delegate :consultation, to: :consultee
    delegate :planning_application, to: :consultation

    attr_readonly :response

    enum :summary_tag, {
      amendments_needed: "amendments_needed",
      no_objections: "no_objections",
      refused: "refused"
    }, scopes: false

    validates :name, :response, :summary_tag, :received_at, presence: true

    scope :redacted, -> { where.not(redacted_response: "") }

    after_create do
      consultee.update!(status: "responded", last_response_at: Time.current)
    end

    class << self
      def default_scope
        preload(documents: :file_attachment)
      end
    end

    def name
      super || consultee.name
    end

    def email
      super || consultee.email_address
    end

    def truncated_comment
      comment.truncate(100, separator: " ")
    end

    def comment
      (redacted_response.presence || response)
    end

    def documents=(files)
      files.select(&:present?).each do |file|
        documents.new(file: file)
      end
    end
  end
end
