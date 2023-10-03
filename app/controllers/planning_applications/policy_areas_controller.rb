# frozen_string_literal: true

module PlanningApplication
  class PolicyAreasController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_policy_area, only: %i[show edit update]
    before_action :set_considerations, only: %i[new edit]

    def show; end

    def new
      @policy_area = @planning_application.build_policy_area
    end

    def edit; end

    def create
      @policy_area = @planning_application.build_policy_area(assign_params.except(:areas))

      if @policy_area.save
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("policy_areas.successfully_created")
      else
        set_considerations
        render :new
      end
    end

    def update
      if @policy_area.update(assign_params.except(:areas))
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("policy_areas.successfully_updated")
      else
        set_considerations
        render :edit
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def set_policy_area
      @policy_area = @planning_application.policy_area
    end

    def status
      mark_as_complete? ? :complete : :in_progress
    end

    def policy_area_params
      params.require(:policy_area)
            .permit(
              areas: [],
              considerations_attributes: %i[area policies guidance assessment id]
            )
            .to_h.merge(status:)
    end

    def assign_params
      considerations_attributes = policy_area_params[:considerations_attributes].select do |_key, value|
        value[:policies].present? || value[:guidance].present? || value[:assessment].present?
      end

      new_params = policy_area_params

      new_params[:considerations_attributes] = considerations_attributes
      new_params
    end

    def set_considerations
      areas = @policy_area.present? ? @policy_area.considerations.map(&:area) : []
      current_considerations = @policy_area.present? ? @policy_area.considerations : []

      considerations = (PolicyArea::AREAS - areas).map do |area|
        Consideration.new(area:)
      end

      @considerations = (considerations + current_considerations).sort_by(&:area)
    end
  end
end
