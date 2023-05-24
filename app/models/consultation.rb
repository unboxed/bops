# frozen_string_literal: true

class Consultation < ApplicationRecord
  belongs_to :planning_application
  has_many :consultees
  has_many :neighbours

  accepts_nested_attributes_for :consultees, :neighbours
end
