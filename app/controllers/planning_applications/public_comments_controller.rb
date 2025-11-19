# frozen_string_literal: true

module PlanningApplications
  class PublicCommentsController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_user_is_reviewer_checking_assessment

    def edit
      respond_to do |format|
        format.html { render :edit }
      end
    end

    def update
      respond_to do |format|
        if @planning_application.update(planning_application_params)
          format.html do
            redirect_to planning_application_review_tasks_path(@planning_application),
              notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def planning_application_params
      params.require(:planning_application).permit(:public_comment)
    end
  end
end
