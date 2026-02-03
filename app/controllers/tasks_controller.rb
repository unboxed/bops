# frozen_string_literal: true

class TasksController < AuthenticationController
  include BopsCore::TasksController

  before_action :set_planning_application
  before_action :show_sidebar
  before_action :show_header
  before_action :build_form

  private

  def template_for(action)
    ["", "bops_core/"].each do |engine|
      path = "#{engine}tasks/#{@task.full_slug}/#{action}"
      return path if lookup_context.exists?(path)
    end

    "tasks/generic/#{action}"
  end

  def build_form
    [Tasks, BopsCore::Tasks].each do |engine|
      klass = engine.form_for(@task.slug)
      next unless klass

      @form = klass.new(@task, params)

      break if @form
    end
  end
end
