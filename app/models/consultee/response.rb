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
      approved: "approved",
      objected: "objected"
    }, scopes: false

    validates :name, :response, :summary_tag, :received_at, presence: true

    with_options on: :redaction do
      validates :redacted_by, presence: true
      validates :redacted_response, presence: true
    end

    after_create do
      consultee.update!(status: "responded", last_response_at: Time.current)
    end

    class << self
      def default_scope
        preload(documents: :file_attachment).order(:received_at, :id)
      end

      def redacted
        where.not(redacted_response: "")
      end
    end

    def name
      super || consultee.name
    end

    def email
      super || consultee.email_address
    end

    def received_at
      super || Date.current
    end

    def truncated_comment
      comment.truncate(100, separator: " ")
    end

    def comment
      redacted_response.presence || response
    end

    def published?
      redacted_response.present?
    end

    def documents=(files)
      files.select(&:present?).each do |file|
        documents.new(file: file)
      end
    end
  end
end
