# frozen_string_literal: true

module BopsPreapps
  class CancelRequestsController < AuthenticationController
    before_action :set_case_record
    before_action :set_planning_application
    before_action :find_task
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
          if @form.update(params)
            redirect_to @form.redirect_url, notice: @form.flash(:notice, self)
          else
            flash.now[:alert] = @form.flash(:alert, self)
            render :show, status: :unprocessable_entity
          end
        end
      end
    end

    private

    def set_case_record
      @case_record = PlanningApplication.find_by!(reference: params[:reference]).case_record
    end

    def set_planning_application
      @planning_application = PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end

    def find_task
      @task = @case_record.find_task_by_slug_path!(params[:task_slug])
    end

    def build_form
      @form = BopsPreapps::Tasks::CancelValidationRequestForm.new(@task)
      @form.validation_request_id = params[:validation_request_id]
    end

    def show_header
      @show_header_bar ||= true
    end

    def show_sidebar
      @show_sidebar ||= @task.top_level_ancestor
    end
  end
end
