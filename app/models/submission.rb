# frozen_string_literal: true

class Submission < ApplicationRecord
  include AASM

  belongs_to :local_authority
  has_one :case_record, dependent: :nullify
  has_many :documents, dependent: :destroy

  with_options through: :case_record, source: :caseable, dependent: :nullify do
    has_one :enforcement, source_type: "Enforcement"
    has_one :planning_application, source_type: "PlanningApplication"
  end

  validates :external_uuid, uniqueness: true, allow_nil: true

  with_options presence: true do
    validates :request_body
    validates :request_headers
  end

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  aasm column: :status, timestamps: true do
    state :submitted, initial: true
    state :started
    state :failed
    state :completed

    event :start do
      transitions from: [:failed, :submitted], to: :started
    end

    event :fail do
      transitions from: [:submitted, :started], to: :failed
    end

    event :complete do
      transitions from: :started, to: :completed
    end
  end

  store_accessor :application_payload, :json_file, :other_files

  def application_reference
    @application_reference ||= request_body["applicationRef"] || request_body["metadata"]["id"]
  end

  def document_link_urls
    @document_link_urls ||= request_body.fetch("documentLinks", []).pluck("documentLink")
  end

  def source
    @source ||= request_body.dig("metadata", "source") || "Planning Portal"
  end

  def request_body
    super.with_indifferent_access
  end

  def planning_portal?
    source == "Planning Portal"
  end

  def planx?
    source == "PlanX"
  end
end
