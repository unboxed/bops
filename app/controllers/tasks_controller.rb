# frozen_string_literal: true

class TasksController < AuthenticationController
  include BopsCore::TasksController

  def tasks_modules = [Tasks, BopsCore::Tasks]

  before_action :set_planning_application
  before_action :show_sidebar
  before_action :show_header
  before_action :build_form

  private

  def failure_template
    return :edit if params[:task_action] == "update_neighbour_response"
    super
  end
end
