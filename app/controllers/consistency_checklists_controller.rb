# frozen_string_literal: true

class ConsistencyChecklistsController < AuthenticationController
  include CommitMatchable

  before_action :set_planning_application
  before_action :set_consistency_checklist, except: %i[new create]

  def show; end

  def new
    @consistency_checklist = @planning_application.build_consistency_checklist
  end

  def edit; end

  def create
    @consistency_checklist = @planning_application.build_consistency_checklist(
      consistency_checklist_params.except(:proposal_measurement)
    )

    if @consistency_checklist.save
      update_proposal_measurements

      redirect_to(
        planning_application_assessment_tasks_path(@planning_application),
        notice: t(".successfully_updated_application")
      )
    else
      render :new
    end
  end

  def update
    if @consistency_checklist.update(consistency_checklist_params.except(:proposal_measurement))
      update_proposal_measurements

      redirect_to(
        planning_application_assessment_tasks_path(@planning_application),
        notice: t(".successfully_updated_application")
      )
    else
      render :new
    end
  end

  private

  def set_consistency_checklist
    @consistency_checklist = @planning_application.consistency_checklist
  end

  def consistency_checklist_params
    params
      .require(:consistency_checklist)
      .permit(permitted_params)
      .merge(status:)
  end

  def permitted_params
    [
      :description_matches_documents,
      :documents_consistent,
      :proposal_details_match_documents,
      :proposal_details_match_documents_comment,
      :site_map_correct,
      :proposal_measurements_match_documents,
      { proposal_measurement: %i[eaves_height max_height depth] }
    ]
  end

  def status
    mark_as_complete? ? :complete : :in_assessment
  end

  def update_proposal_measurements
    return unless @consistency_checklist.proposal_measurements_match_documents == "no"

    height = @planning_application.proposal_measurement.max_height
    depth = @planning_application.proposal_measurement.depth
    eaves_height = @planning_application.proposal_measurement.eaves_height

    @planning_application
      .proposal_measurement
      .update(consistency_checklist_params[:proposal_measurement])

    Audit.create!(
      planning_application_id: @planning_application.id,
      user: Current.user,
      activity_type: "proposal_measurements_updated",
      audit_comment:
        "Proposal measurements were updated from height: #{height}m,
        eaves height: #{eaves_height}m, depth: #{depth}m,
        to height: #{@planning_application.proposal_measurement.max_height}m,
        eaves height: #{@planning_application.proposal_measurement.eaves_height}m,
        depth: #{@planning_application.proposal_measurement.depth}m"
    )
  end
end
