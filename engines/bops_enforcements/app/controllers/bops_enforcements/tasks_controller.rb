# frozen_string_literal: true

module BopsEnforcements
  class TasksController < ApplicationController
    include BopsCore::TasksController

    before_action :set_enforcement
    before_action :build_form, only: %i[edit update]
    before_action :ensure_case_is_not_closed, only: %i[show edit update]

    private

    def set_enforcement
      @enforcement = @case_record.caseable
    end

    def template_for(action)
      path = "bops_enforcements/tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "bops_enforcements/tasks/generic/#{action}"
    end

    def build_form
      klass = BopsEnforcements::Tasks.form_for(@task.slug)

      @form = klass.new(@task)
    end

    def ensure_case_is_not_closed
      return unless @enforcement.closed?

      redirect_to bops_enforcements.enforcement_path(@enforcement), alert: t(".failure")
    end
  end
end
