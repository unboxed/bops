# frozen_string_literal: true

class Condition < ApplicationRecord
  validates :text, :reason, presence: true

  belongs_to :planning_application

  attr_accessor :new_condition, :conditions
end
