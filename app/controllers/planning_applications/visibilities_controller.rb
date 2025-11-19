# frozen_string_literal: true

module PlanningApplications
  class VisibilitiesController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_planning_application_is_publishable, only: %i[new]
    before_action :ensure_site_notice_displayed_at, only: %i[create]
    before_action :ensure_press_notice_published_at, only: %i[create]

    def new
      respond_to do |format|
        format.html { render :new }
      end
    end

    def show
      respond_to do |format|
        format.html { render :show }
      end
    end

    def create
      respond_to do |format|
        @planning_application.assign_attributes(determination_date_params)

        if @planning_application.valid?
          @planning_application.determine!

          @planning_application.send_decision_notice_mail(request.host)

          format.html do
            redirect_to @planning_application, notice: t(".success")
          end
        else
          format.html { render :show }
        end
      end
    end

    private

    def determination_date_params
      params.require(:planning_application).permit(:determination_date)
    end

    def ensure_planning_application_is_publishable
      return if @planning_application.can_publish?

      redirect_to planning_application_assessment_tasks_path(@planning_application),
        alert: t(
          ".not_publishable",
          application_type: @planning_application.application_type.description
        )
    end

    def ensure_site_notice_displayed_at
      return unless @planning_application.site_notice_needs_displayed_at?

      flash.now[:alert] = t(
        ".confirm_site_notice_displayed_at_html",
        href: edit_planning_application_site_notice_path(@planning_application, @planning_application.site_notice)
      )
      render :show and return
    end

    def ensure_press_notice_published_at
      return unless @planning_application.press_notice_needs_published_at?

      flash.now[:alert] = t(
        ".confirm_press_notice_published_at_html",
        href: planning_application_press_notice_confirmation_path(@planning_application)
      )
      render :show and return
    end
  end
end
