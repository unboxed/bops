# frozen_string_literal: true

class ConstraintsCreationService
  def initialize(planning_application:, constraints_params:, constraints_query: nil)
    @planning_application = planning_application
    @constraints_params = constraints_params
    @constraints_query = constraints_query
  end

  def call
    constraints.each do |constraint|
      existing_constraint = Constraint.options_for_local_authority(planning_application.local_authority_id)
                                      .find_by("LOWER(type)= ?", constraint.downcase)

      if existing_constraint
        planning_application.planning_application_constraints.find_or_create_by!(
          constraint_id: existing_constraint.id,
          planning_application_constraints_query: @constraints_query
        ).save!
      else
        planning_application.constraints.find_or_create_by!(
          type: constraint.parameterize.underscore,
          category: "local", local_authority_id: planning_application.local_authority_id
        )
      end
    end

    previous_constraints =
      planning_application.planning_application_constraints.active
    previous_constraints.each do |constraint|
      next if constraints.include?(constraint.constraint.type.parameterize.underscore)

      constraint.update!(removed_at: Time.current)
    end
  rescue ActiveRecord::RecordInvalid, NoMethodError => e
    Appsignal.send_error(e)
  end

  private

  attr_reader :planning_application, :constraints_params

  def constraints
    if constraints_params.present?
      constraints_params.filter_map do |key, value|
        key.parameterize.underscore if value
      end
    else
      []
    end
  end
end
