# frozen_string_literal: true

class ConstraintsCreationService
  def initialize(planning_application:, constraints_params:)
    @planning_application = planning_application
    @constraints_params = constraints_params
  end

  def call
    constraints.each do |constraint|
      query = PlanningApplicationConstraintsQuery.create!(
        planning_application:,
        geojson: planning_application.boundary_geojson,
        wkt: constraint["wkt"],
        planx_query: constraint["planxRequest"] || constraint["planx_url"],
        planning_data_query: constraint["sourceRequest"]
      )

      current_constraints = constraint["constraints"].filter { |_, present_constraint| present_constraint["value"] }

      current_constraints.each do |k, v|
        existing_constraint = Constraint.find_by("LOWER(type)= ?", k.parameterize.underscore)

        if existing_constraint
          metadata = constraint["metadata"][k] if constraint["metadata"]

          planning_application.planning_application_constraints.create!(
            constraint_id: existing_constraint.id,
            planning_application_constraints_query: query,
            identified: true,
            identified_by: planning_application.api_user.name,
            data: v["data"],
            metadata:
          )
        else
          Appsignal.send_error("Unexpected constraint type: #{k}, category #{v['category']}")
        end
      end
    end

    previous_constraints =
      planning_application.planning_application_constraints.active
    previous_constraints.each do |pa_constraint|
      next if present_constraints.include?(pa_constraint.constraint.type)

      pa_constraint.update!(removed_at: Time.current)
    end
  rescue ActiveRecord::RecordInvalid, NoMethodError => e
    Appsignal.send_error(e)
  end

  private

  attr_reader :planning_application, :constraints_params

  def constraints
    @constraints ||= Array.wrap(constraints_params)
  end

  def present_constraints
    constraints.filter_map do |constraint|
      constraint["constraints"].filter_map do |key, value|
        key.parameterize.underscore if value["value"]
      end
    end.flatten
  end
end
