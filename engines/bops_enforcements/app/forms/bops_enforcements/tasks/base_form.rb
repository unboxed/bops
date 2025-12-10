# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class BaseForm
      include ActiveModel::Model
      include BopsEnforcements::Engine.routes.url_helpers

      attr_reader :task, :case_record
      delegate :parent, :slug, to: :task

      def initialize(task)
        @task = task
        @case_record = @task.case_record
      end

      def update(params)
        task.update(permitted_fields(params))
      end

      def permitted_fields(params)
        params.require(:task).permit(:status, :started_at, :completed_at)
      end

      def redirect_url
        enforcement_path(@case_record)
      end

      def flash(type, controller)
        case type
        when :notice
          controller.t(".#{slug}.success")
        when :alert
          controller.t(".#{slug}.failure")
        end
      end
    end
  end
end
