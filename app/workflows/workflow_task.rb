# frozen_string_literal: true

class WorkflowTask
  include Rails.application.routes.url_helpers

  def initialize(planning_application)
    @planning_application = planning_application
    @task_list_link_text = nil
    @task_list_link = nil
    @task_list_status = :unknown
  end

  attr_reader :task_list_link_text, :task_list_link, :task_list_status

  def render?
    true
  end

  private

  attr_reader :planning_application
end
