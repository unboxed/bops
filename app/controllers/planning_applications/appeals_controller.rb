# frozen_string_literal: true

module PlanningApplications
  class AppealsController < AuthenticationController
    before_action :set_planning_application
    before_action :redirect_to_application, unless: :appeals_permitted?
    before_action :set_appeal

    def new
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def create
      @appeal.assign_attributes(appeal_params)

      respond_to do |format|
        if @appeal.save
          format.html do
            redirect_to planning_application_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :new }
        end
      end
    end

    private

    def build_appeal
      @planning_application.build_appeal
    end

    def set_appeal
      @appeal = @planning_application.appeal || build_appeal
    end

    def appeals_permitted?
      @planning_application.appeals?
    end

    def appeal_params
      params.require(:appeal).permit(:reason, :lodged_at, documents: [])
    end

    def redirect_to_application
      redirect_to planning_application_path(@planning_application), alert: t(".not_found")
    end
  end
end
