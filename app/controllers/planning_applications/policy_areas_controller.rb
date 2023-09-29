# frozen_string_literal: true

module PlanningApplication
  class PolicyAreasController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_policy_area, only: %i[show edit update]

    def show; end

    def new
      @policy_area = @planning_application.build_policy_area
      @considerations = @policy_area.considerations.new
    end

    def edit; end

    def create
      boos = policy_area_params[:areas].compact_blank

      policy_area_params[:considerations_attributes].each do |hash|
        unless boos.include? hash[1][:area]
          policy_area_params.reject(hash)
        end
      end
      @policy_area = @planning_application.build_policy_area(policy_area_params)

      if @policy_area.save
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("policy_areas.successfully_created")
      else
        render :new
      end
    end

    def update
      if @policy_area.update(policy_area_params)
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("policy_areas.successfully_updated")
      else
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
      @policy_area = @planning_application.policy_areas
    end

    def status
      mark_as_complete? ? :complete : :in_progress
    end

    def policy_area_params
      params.require(:policy_area)
        .permit(
          areas: [],
          considerations_attributes: [:area, :policies, :guidance, :assessment]
        )
        .to_h.merge(status:)
    end
  end
end
