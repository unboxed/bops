# frozen_string_literal: true

class CancelRequestsController < AuthenticationController
  before_action :set_planning_application
  before_action :set_task
  before_action :build_form
  before_action :show_sidebar
  before_action :show_header

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @form.save
          redirect_to task_path(@planning_application.reference, @task.full_slug), notice: t(".#{@task.slug}.cancel_request")
        else
          render :show, status: :unprocessable_content
        end
      end
    end
  end

  private

  def set_task
    @task = @planning_application.case_record.find_task_by_slug_path!(params[:task_slug])
  end

  def build_form
    @validation_request = @planning_application.validation_requests.find(params[:validation_request_id])
    @form = BopsCore::CancelValidationRequestForm.new(
      planning_application: @planning_application,
      task: @task,
      validation_request: @validation_request,
      **form_params
    )
  end

  def form_params
    params.fetch(:cancel_validation_request_form, {}).permit(:cancel_reason)
  end
end
