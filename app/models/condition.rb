# frozen_string_literal: true

class Condition < ApplicationRecord
  validates_presence_of :text, :reason

  belongs_to :planning_application

  attr_accessor :title
end
