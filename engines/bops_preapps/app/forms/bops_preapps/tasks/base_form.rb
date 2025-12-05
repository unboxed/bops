# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class BaseForm
      include ActiveModel::Model
      include BopsPreapps::Engine.routes.url_helpers

      attr_reader :task, :case_record, :planning_application, :button
      delegate :parent, to: :task

      def initialize(task)
        @task = task
        @case_record = @task.case_record
        @planning_application = @task.case_record.planning_application
      end

      def update(params)
        task.update(params)
      end

      def permitted_fields(params)
        params.require(:task).permit(:status, :started_at, :completed_at)
      end

      def redirect_url
        task_path(planning_application, task)
      end

      def save_draft?
        button == "save_draft"
      end
    end
  end
end
