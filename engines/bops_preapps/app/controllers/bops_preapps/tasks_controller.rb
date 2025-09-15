# frozen_string_literal: true

module BopsPreapps
  class TasksController < ApplicationController
    include BopsCore::TasksController

    before_action :set_planning_application, only: %i[show]
    before_action :build_form, only: %i[edit update]
    # before_action :ensure_case_is_not_closed, only: %i[show edit update]

    private

    def set_planning_application
      @planning_application = @case_record.caseable
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
