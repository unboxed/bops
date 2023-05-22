# frozen_string_literal: true

class PlanningApplicationConstraintsQuery < ApplicationRecord
  validates :geojson, :wkt, :planx_query, :planning_data_query, presence: true

  belongs_to :planning_application
  has_many :planning_application_constraints, dependent: :destroy
  has_many :constraints, through: :planning_application_constraints
end
