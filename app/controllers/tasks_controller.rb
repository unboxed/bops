# frozen_string_literal: true

class TasksController < AuthenticationController
  include BopsCore::TasksController

  def tasks_modules = [Tasks, BopsCore::Tasks]

  before_action :set_planning_application
  before_action :show_sidebar
  before_action :show_header
  before_action :build_form
end
