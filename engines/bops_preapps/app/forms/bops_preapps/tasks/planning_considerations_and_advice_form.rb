# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class PlanningConsiderationsAndAdviceForm < Form
      self.task_actions = %w[save_draft save_and_complete add_consideration]

      def initialize(task, params = {})
        super

        @consideration_set = planning_application.consideration_set
        @considerations = @consideration_set.considerations.select(&:persisted?)
        @consideration = @consideration_set.considerations.new(draft: true)
      end

      attr_reader :considerations, :consideration

      attribute :policy_area, :string

      with_options on: :add_consideration do
        validates :policy_area, presence: {message: "Please select a policy area"}
      end

      def flash(type, controller)
        case action
        when "add_consideration", "save_draft"
          case type
          when :notice
            controller.t(".#{slug}.#{action}.success")
          when :alert
            if planning_application&.consideration_set&.considerations&.any?(&:persisted?)
              "You have already added this consideration to this assessment, it cannot be added twice."
            else
              planning_application&.consideration_set&.considerations&.any?(&:persisted?)
              controller.t(".#{slug}.#{action}.failure")
            end
          end
        else
          super
        end
      end

      private

      def create_consideration!
        @consideration_set.considerations.create! do |consideration|
          consideration.policy_area = policy_area
          consideration.draft = true
          consideration.submitted_by = Current.user
        end
      end

      def add_consideration
        transaction do
          create_consideration! && task.start!
        end
      end
    end
  end
end
