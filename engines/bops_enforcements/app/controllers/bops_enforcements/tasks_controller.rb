# frozen_string_literal: true

module BopsEnforcements
  class TasksController < ApplicationController
    include BopsCore::TasksController

    before_action :set_enforcement
    before_action :build_form, only: %i[edit update]

    private

    def set_enforcement
      @enforcement = @case_record.caseable
    end

    def template_for(action)
      path = "bops_enforcements/tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "tasks/generic/#{action}"
    end

    def build_form
      klass = BopsEnforcements::Tasks.form_for(@task.slug)

      @form = klass.new(@task)
    end
  end
end
