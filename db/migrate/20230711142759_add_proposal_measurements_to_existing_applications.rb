# frozen_string_literal: true

class AddProposalMeasurementsToExistingApplications < ActiveRecord::Migration[7.0]
  def change
    prior_approval = ApplicationType.find_by(name: "prior_approval")
    PlanningApplication.where(application_type: prior_approval).find_each do |planning_application|
      next if planning_application.proposal_measurement

      ProposalMeasurement.create(
        planning_application_id: planning_application.id,
        max_height: planning_application.max_height_extension.to_f,
        eaves_height: planning_application.eave_height_extension.to_f,
        depth: planning_application.rear_wall_length.to_f
      )
    end
  end
end
