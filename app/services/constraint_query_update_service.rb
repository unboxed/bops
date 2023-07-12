# frozen_string_literal: true

class ConstraintQueryUpdateService
  class SaveError < StandardError; end

  def initialize(planning_application:)
    @planning_application = planning_application
    @geojson = @planning_application.boundary_geojson
  end

  attr_reader :planning_application, :geojson

  def call
    results = Apis::PlanX::Query.query(geojson:)

    return if results[:constraints].blank?

    query = PlanningApplicationConstraintsQuery.new(
      planning_application:,
      geojson: results[:geojson],
      wkt: results[:wkt],
      planx_query: results[:planx_url],
      planning_data_query: results[:sourceRequest]
    )

    query.save!

    present_constraints = results[:constraints].filter { |_, constraint| constraint[:value] }
    constraints_params = present_constraints.to_h do |constraint_key, _constraint_hash|
      [constraint_key.to_s.split(".").last.underscore, true]
    end

    ConstraintsCreationService.new(planning_application:, constraints_params:,
                                   constraints_query: query).call
  rescue ActiveRecord::RecordInvalid => e
    raise SaveError, e.message
  end
end
