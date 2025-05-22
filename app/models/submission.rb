# frozen_string_literal: true

class Submission < ApplicationRecord
  include AASM

  belongs_to :local_authority
  with_options dependent: :nullify do
    has_many :documents
    has_one :planning_application
  end

  validates :external_uuid, uniqueness: true, allow_nil: true

  with_options presence: true do
    validates :request_body
    validates :request_headers
  end

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

  store_accessor :metadata, :json_file, :other_files

  def application_reference
    request_body["applicationRef"]
  end
end
