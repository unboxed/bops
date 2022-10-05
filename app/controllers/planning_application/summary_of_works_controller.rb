# frozen_string_literal: true

class PlanningApplication
  class SummaryOfWorksController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :set_summary_of_work, only: %i[show edit update]

    def new
      @summary_of_work = @planning_application.summary_of_works.new

      respond_to do |format|
        format.html
      end
    end

    def create
      @summary_of_work = @planning_application.summary_of_works.new(summary_of_works_params).tap do |record|
        record.user = current_user
        record.status = status
      end

      respond_to do |format|
        if @summary_of_work.save
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application),
                        notice: "Summary of works was successfully created."
          end
        else
          format.html { render :new }
        end
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @summary_of_work.assign_attributes(user: current_user, status: status)

      respond_to do |format|
        if @summary_of_work.update(summary_of_works_params)
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application),
                        notice: "Summary of works was successfully updated."
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def set_planning_application
      @planning_application = planning_applications_scope.find(planning_application_id)
    end

    def set_summary_of_work
      @summary_of_work = @planning_application.summary_of_works.find(summary_of_work_id)
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def summary_of_work_id
      Integer(params[:id])
    end

    def summary_of_works_params
      params.require(:summary_of_work).permit(:entry)
    end

    def status
      save_progress? ? "in_progress" : "completed"
    end

    def ensure_planning_application_is_validated
      return if @planning_application.validated?

      render plain: "forbidden", status: :forbidden
    end
  end
end
