# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class PlanningConsiderationsAndAdviceForm < BaseForm
      def initialize(task, params = {})
        super

        @consideration_set = planning_application.consideration_set
        @considerations = @consideration_set.considerations.select(&:persisted?)
        @consideration = @consideration_set.considerations.new(draft: true)
      end
      attr_reader :considerations, :consideration

      def update(params)
        if params[:button] == "save_draft"
          task.start!
        else
          task.complete!
        end
      end

      def permitted_fields(params)
        params # no params sent: just a submit button
      end
    end
  end
end
