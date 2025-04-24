# frozen_string_literal: true

class Submission < ApplicationRecord
  include AASM

  belongs_to :local_authority
  has_one :planning_application, dependent: :nullify

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
      transitions from: :submitted, to: :started
    end

    event :fail do
      transitions from: [:submitted, :started], to: :failed
    end

    event :complete do
      transitions from: :started, to: :completed
    end
  end
end
