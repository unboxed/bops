# frozen_string_literal: true

module BopsCore
  module TasksController
    extend ActiveSupport::Concern

    included do
      wrap_parameters false

      before_action :set_case_record
      before_action :find_task
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
            redirect_to @form.redirect_url, notice: t(".#{@task.slug}.success")
          else
            render template_for(:show), alert: t(".#{@task.slug}.failure")
          end
        end
      end
    end

    private

    def set_case_record
      @case_record = if params[:reference]
        PlanningApplication.find_by(reference: params[:reference]).case_record
      else
        @current_local_authority.case_records.find(params[:case_id])
      end
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
  end
end
