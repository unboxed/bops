# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteDescriptionForm < Form
      self.task_actions = %w[save_draft save_and_complete]

      attribute :site_description, :string

      with_options on: %i[save_draft save_and_complete] do
        validates :site_description,
          presence: {
            message: "Enter a description for the site"
          }
      end

      after_initialize do
        self.site_description = assessment_detail.entry
      end

      delegate :assessment_details, to: :planning_application

      def address
        planning_application.full_address
      end

      def update(params)
        super do
          case action
          when "save_draft"
            save_draft
          when "save_and_complete"
            save_and_complete
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      private

      def find_or_initialize_assessment_detail
        assessment_details.find_or_initialize_by(category: :site_description)
      end

      def assessment_detail
        @assessment_detail ||= find_or_initialize_assessment_detail
      end

      def update_assessment_detail!
        assessment_detail.update!(entry: site_description)
      end

      def save_draft
        transaction do
          update_assessment_detail! && task.start!
        end
      end

      def save_and_complete
        transaction do
          update_assessment_detail! && task.complete!
        end
      end
    end
  end
end
