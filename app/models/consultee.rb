# frozen_string_literal: true

class Consultee < ApplicationRecord
  belongs_to :planning_application
  belongs_to :consultation, optional: true

  validates :name, :origin, presence: true

  enum origin: { internal: 0, external: 1 }

  scope :with_response, -> { where.not(response: nil) }
end
