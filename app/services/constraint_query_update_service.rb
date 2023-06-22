# frozen_string_literal: true

class ConstraintQueryUpdateService
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  def call
    geojson = @planning_application.boundary_geojson
    planx = Apis::PlanX::Query.new
    results = planx.fetch(geojson:)

    return if results[:constraints].blank?

    query = PlanningApplicationConstraintsQuery.new(
      planning_application: @planning_application,
      geojson: results[:geojson],
      wkt: results[:wkt],
      planx_query: results[:planx_url],
      planning_data_query: results[:url]
    )

    query.save!

    present_constraints = results[:constraints].filter { |_, constraint| constraint[:value] }
    constraints_params = present_constraints.to_h do |constraint_key, _constraint_hash|
      [constraint_key.to_s.split(".").last.underscore, true]
    end

    ConstraintsCreationService.new(planning_application: @planning_application, constraints_params:).call
  end
end
