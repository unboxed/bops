# frozen_string_literal: true

class PlanningApplicationConstraintsQuery < ApplicationRecord
  validates :planx_query, :planning_data_query, presence: true

  belongs_to :planning_application
  has_many :planning_application_constraints, dependent: :destroy
  has_many :constraints, through: :planning_application_constraints

  validate :coordinate_method_presence

  def coordinate_method_presence
    return unless coordinate_methods_empty?

    errors.add(:base, :coordinate_method_not_present)
  end

  private

  def coordinate_methods_empty?
    geojson.blank? && wkt.blank?
  end
end
