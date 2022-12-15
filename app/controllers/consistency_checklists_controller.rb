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
      consistency_checklist_params
    )

    if @consistency_checklist.save
      redirect_to(
        planning_application_assessment_tasks_path(@planning_application),
        notice: t(".successfully_updated_application")
      )
    else
      render :new
    end
  end

  def update
    if @consistency_checklist.update(consistency_checklist_params)
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
      .merge(status: status)
  end

  def permitted_params
    %i[
      description_matches_documents
      documents_consistent
      proposal_details_match_documents
      proposal_details_match_documents_comment
      site_map_correct
    ]
  end

  def status
    mark_as_complete? ? :complete : :in_assessment
  end
end
