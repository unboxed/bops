# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application
  has_one :review, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :conditions, extend: ConditionsExtension, dependent: :destroy

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :review
end
