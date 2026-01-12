# frozen_string_literal: true

class ConstraintsCreationService
  IGNORED_CONSTRAINTS = %w[
    road_classified
  ].freeze

  def initialize(planning_application:, constraints_params:)
    @planning_application = planning_application
    @constraints_params = constraints_params
  end

  def call
    existing_constraints = planning_application_constraints.index_by(&:type)

    constraint_requests.each do |request|
      query = PlanningApplicationConstraintsQuery.create!(
        planning_application:,
        geojson: planning_application.boundary_geojson,
        wkt: request["wkt"],
        planx_query: request["planxRequest"],
        planning_data_query: request["sourceRequest"]
      )

      request["constraints"].each do |key, constraint|
        underscore_key = key.parameterize.underscore
        existing_constraint = existing_constraints.delete(underscore_key)

        if existing_constraint
          if constraint["value"]
            existing_constraint.update!(
              planning_application_constraints_query: query,
              identified: true,
              identified_by: identified_by,
              data: constraint["data"],
              metadata: constraint.dig("metadata", key)
            )
          else
            existing_constraint.destroy!
          end
        elsif constraint["value"]
          constraint_type = Constraint.find_by("LOWER(type)= ?", underscore_key)

          if constraint_type
            planning_application_constraints.create!(
              constraint: constraint_type,
              planning_application_constraints_query: query,
              identified: true,
              identified_by: identified_by,
              data: constraint["data"],
              metadata: constraint.dig("metadata", key)
            )
          else
            Appsignal.report_error("Unexpected constraint type: #{key}, category #{constraint["category"]}")
          end
        end
      end
    end

    existing_constraints.delete(*IGNORED_CONSTRAINTS)
    existing_constraints.each(&:destroy!)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotDestroyed => e
    Appsignal.report_error(e)
  end

  private

  attr_reader :planning_application, :constraints_params
  delegate :planning_application_constraints, to: :planning_application
  delegate :api_user, to: :planning_application, allow_nil: true

  def constraint_requests
    Array.wrap(constraints_params)
  end

  def identified_by
    api_user&.name || "BOPS"
  end
end
