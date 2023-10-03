# frozen_string_literal: true

class ConstraintQueryUpdateService
  def initialize(planning_application:)
    @planning_application = planning_application
    @geojson = @planning_application.boundary_geojson
  end

  attr_reader :planning_application, :geojson

  def call
    results = Apis::PlanX::Query.query(geojson:)

    return if results[:constraints].blank?

    ConstraintsCreationService.new(planning_application:, constraints_params: results.with_indifferent_access).call
  end
end
