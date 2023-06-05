# frozen_string_literal: true

class Consultation < ApplicationRecord
  belongs_to :planning_application
  has_many :consultees, dependent: :destroy
  has_many :neighbours, dependent: :destroy
  has_many :neighbour_letters, through: :neighbours

  accepts_nested_attributes_for :consultees, :neighbours

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    complete: "complete"
  }
end
