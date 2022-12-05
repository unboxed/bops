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
        after_save_path,
        notice: t(".successfully_updated_application")
      )
    else
      render :new
    end
  end

  def update
    if @consistency_checklist.update(consistency_checklist_params)
      redirect_to(
        after_save_path,
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

  def after_save_path
    if after_save_path_request_type.present?
      send(
        "new_planning_application_#{after_save_path_request_type}_validation_request_path",
        @planning_application,
        consistency_checklist: true
      )
    else
      planning_application_assessment_tasks_path(@planning_application)
    end
  end

  def after_save_path_request_type
    %i[additional_document description_change red_line_boundary_change].find do |request_type|
      t("consistency_checklists.request_#{request_type}") == params[:commit]
    end
  end

  def status
    mark_as_complete? ? :complete : :in_assessment
  end
end
