# frozen_string_literal: true

module BopsPreapps
  class TasksController < AuthenticationController
    include BopsCore::TasksController

    before_action :set_planning_application
    before_action :build_form

    private

    def set_planning_application
      @planning_application = PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end

    def template_for(action)
      path = "bops_preapps/tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "bops_preapps/tasks/generic/#{action}"
    end

    def build_form
      klass = BopsPreapps::Tasks.form_for(@task.slug)

      @form = klass.new(@task)
    end
  end
end
