# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application

  has_many :conditions, extend: ConditionsExtension

  accepts_nested_attributes_for :conditions, allow_destroy: true
end
