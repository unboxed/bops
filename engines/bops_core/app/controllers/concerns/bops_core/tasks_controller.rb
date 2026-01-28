# frozen_string_literal: true

module BopsCore
  module TasksController
    extend ActiveSupport::Concern

    included do
      wrap_parameters false

      before_action :set_case_record
      before_action :find_task
      before_action :set_planning_application
      before_action :show_sidebar
      before_action :show_header
    end

    def show
      respond_to do |format|
        format.html { render template_for(:show) }
      end
    end

    def edit
      respond_to do |format|
        format.html { render template_for(:edit) }
      end
    end

    def update
      respond_to do |format|
        format.html do
          if @form.update(task_params)
            redirect_to @form.redirect_url, notice: @form.flash(:notice, self)
          else
            render template_for(failure_template), alert: @form.flash(:alert, self)
          end
        end
      end
    end

    private

    def set_case_record
      @case_record = if params[:reference]
        PlanningApplication.find_by(reference: params[:reference]).case_record
      elsif params[:planning_application_reference]
        PlanningApplication.find_by(reference: params[:planning_application_reference]).case_record
      else
        @current_local_authority.case_records.find(params[:case_id])
      end
    end

    def show_header
      @show_header_bar ||= true
    end

    def show_sidebar
      @show_sidebar ||= @task.top_level_ancestor
    end

    def set_planning_application
      @planning_application = PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end

    def find_task
      @task = @case_record.find_task_by_slug_path!(params[:slug])
    end

    def build_form
      raise NotImplementedError, "#{self.class} must implement #build_form"
    end

    def task_params
      @form.permitted_fields(params)
    end

    def template_for(action)
      path = "tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "tasks/generic/#{action}"
    end

    def failure_template
      return :edit if params[:task_action] == "update_site_visit"

      :show
    end
  end
end
