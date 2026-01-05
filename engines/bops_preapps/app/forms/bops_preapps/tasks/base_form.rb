# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class BaseForm
      include ActiveModel::Model
      include BopsPreapps::Engine.routes.url_helpers

      attr_reader :task, :case_record, :planning_application, :button, :params
      delegate :parent, :slug, to: :task

      def initialize(task, params = {})
        @task = task
        @params = params
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

      def flash(type, controller)
        case type
        when :notice
          controller.t(".#{slug}.success")
        when :alert
          controller.t(".#{slug}.failure")
        end
      end

      def read_only?
        task.status == "completed"
      end

      def edit_form
        task.in_progress!
      end
    end
  end
end
