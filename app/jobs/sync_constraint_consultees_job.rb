# frozen_string_literal: true

class SyncConstraintConsulteesJob < ApplicationJob
  queue_as :low_priority

  def perform(planning_application_constraint_id)
    planning_application_constraint = PlanningApplicationConstraint.find_by(id: planning_application_constraint_id)
    return if planning_application_constraint.blank?

    planning_application_constraint.sync_consultees!
  rescue => e
    Appsignal.report_error(e)
    raise
  end
end
