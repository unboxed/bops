# frozen_string_literal: true

class PlanningApplication
  class PolicyGuidancesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_policy_guidance, only: %i[show edit update]

    def new
      @policy_guidance = @planning_application.build_policy_guidance
    end

    def create
      @policy_guidance = @planning_application.build_policy_guidance(policy_guidance_params)

      if @policy_guidance.save
        redirect_to planning_application_assessment_tasks_path(@planning_application),
          notice: I18n.t("policy_guidances.successfully_created")
      else
        render :new
      end
    end

    def edit; end

    def update
      if @policy_guidance.update(policy_guidance_params)
        redirect_to planning_application_assessment_tasks_path(@planning_application),
        notice: I18n.t("policy_guidances.successfully_updated")
      else
        render :edit
      end
    end

    def show; end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_applications_scope
      current_local_authority.planning_applications.includes(:notes)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def set_policy_guidance
      @policy_guidance = @planning_application.policy_guidance
    end

    def policy_guidance_params
      params.require(:policy_guidance).permit(:policies, :assessment)
    end
  end
end
