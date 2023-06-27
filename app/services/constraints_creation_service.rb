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
                                      .find_by("LOWER(name)= ?", constraint.downcase)

      if existing_constraint
        planning_application.planning_application_constraints.create!(
          constraint_id: existing_constraint.id,
          planning_application_constraints_query: @constraints_query
        )
      else
        planning_application.constraints.find_or_create_by!(
          name: constraint.titleize, category: "local", local_authority_id: planning_application.local_authority_id
        )
      end
    end

    previous_constraints =
      planning_application.planning_application_constraints.active
                          .where.not(planning_application_constraints_query: nil)
    previous_constraints.each do |constraint|
      constraint.update!(removed_at: Time.current) unless constraints.include?(constraint.constraint.name.humanize)
    end
  rescue ActiveRecord::RecordInvalid, NoMethodError => e
    Appsignal.send_error(e)
  end

  private

  attr_reader :planning_application, :constraints_params

  def constraints
    if constraints_params.present?
      constraints_params.filter_map do |key, value|
        key.humanize if value
      end
    else
      []
    end
  end
end
