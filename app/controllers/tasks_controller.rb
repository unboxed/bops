# frozen_string_literal: true

class TasksController < AuthenticationController
  include BopsCore::TasksController

  before_action :build_form

  private

  def template_for(action)
    path = "tasks/#{@task.full_slug}/#{action}"
    lookup_context.exists?(path) ? path : "tasks/generic/#{action}"
  end

  def build_form
    klass = Tasks.form_for(@task.slug)

    @form = klass.new(@task, params)
  end
end
