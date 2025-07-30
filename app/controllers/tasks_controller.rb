# frozen_string_literal: true

class TasksController < AuthenticationController
  before_action :set_case_record
  before_action :find_task
  before_action :set_enforcement
  before_action :build_form, only: %i[edit update]

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
          redirect_to @form.redirect_url, notice: "Task updated successfully"
        else
          render template_for(:edit)
        end
      end
    end
  end

  private

  def set_case_record
    @case_record = @current_local_authority.case_records.find(params[:case_id])
  end

  def set_enforcement
    @enforcement = @case_record.caseable if @case_record.enforcement?
  end

  def find_task
    @task = @case_record.find_task_by_slug_path!(params[:slug])
  end

  def build_form
    klass = Tasks.form_for(@task.slug)

    @form = klass.new(@task)
  end

  def task_params
    @form.permitted_fields(params)
  end

  def template_for(action)
    path = "tasks/#{@task.full_slug}/#{action}"
    lookup_context.exists?(path) ? path : "tasks/generic/#{action}"
  end
end
