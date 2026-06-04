# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class PlanningConsiderationsAndAdviceForm < Form
      self.task_actions = %w[save_draft save_and_complete add_consideration add_advice update_advice]

      def initialize(task, params = {})
        super

        @consideration_set = planning_application.consideration_set
        @considerations = @consideration_set.considerations.select(&:persisted?)
        @consideration = @consideration_set.considerations.new(draft: true)

        @consideration_for_edit = @consideration_set.considerations.find(consideration_id) if consideration_id
      end

      attr_reader :considerations, :consideration, :consideration_for_edit

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

      def consideration_id
        @consideration_id ||= params[:id] || params.dig(:consideration, :id)
      end

      def create_consideration!
        @consideration_set.considerations.create! do |consideration|
          consideration.policy_area = policy_area
          consideration.draft = true
          consideration.submitted_by = Current.user
        end
      end

      def add_consideration
        create_consideration! && task.start!
      end

      def add_advice
        return false if consideration_params[:summary_tag].blank?
        @consideration.update!(consideration_params) && @task.start!
      end

      def update_advice
        return false if consideration_params[:summary_tag].blank?
        @consideration_for_edit.update!(consideration_params) && @task.start!
      end

      def consideration_params
        params.require(:consideration).permit(
          :policy_area, :draft, :proposal, :summary_tag, :advice, policy_references_attributes: %i[code description url], policy_guidance_attributes: %i[description url]
        )
      end
    end
  end
end
