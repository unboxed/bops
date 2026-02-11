# frozen_string_literal: true

module BopsCore
  module TasksController
    extend ActiveSupport::Concern

    included do
      wrap_parameters false

      before_action :set_case_record
      before_action :find_task
    end

    class_methods do
      private

      def local_prefixes
        [controller_path, "bops_core/tasks"]
      end
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

    def tasks_modules
      [Tasks]
    end

    def set_case_record
      @case_record = if params[:reference]
        PlanningApplication.find_by(reference: params[:reference]).case_record
      elsif params[:planning_application_reference]
        PlanningApplication.find_by(reference: params[:planning_application_reference]).case_record
      else
        @current_local_authority.case_records.find(params[:case_id])
      end
    end

    def find_task
      @task = @case_record.find_task_by_slug_path!(params[:slug])
    end

    def build_form
      tasks_modules.each do |mod|
        klass = mod.form_for(@task.slug)
        next unless klass

        @form = klass.new(@task, params)
        break if @form
      end
    end

    def task_params
      @form.permitted_fields(params)
    end

    def template_for(action)
      tasks_modules.each do |mod|
        path = "#{mod.templates_prefix}/#{@task.full_slug}/#{action}"
        return path if lookup_context.exists?(path)
      end
    end

    def failure_template
      return :edit if params[:task_action] == "update_site_visit"

      :show
    end
  end
end
