# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ChooseApplicationTypeForm < Form
      attribute :recommended_application_type_id, :integer

      with_options on: :save_and_complete do
        validates :recommended_application_type_id,
          presence: {
            message: "Select the recommended type for the application"
          }

        validates :recommended_application_type_id,
          inclusion: {
            in: :application_type_ids,
            message: "Select a recommended type from the list"
          }
      end

      after_initialize do
        self.recommended_application_type_id = planning_application.recommended_application_type_id
      end

      delegate :application_types, to: :local_authority

      def application_type_menu
        application_types.menu
      end

      def application_type_ids
        application_types.ids
      end

      private

      def save_and_complete
        transaction do
          update_planning_application! && task.complete!
        end
      end

      def update_planning_application!
        params = {recommended_application_type_id:}
        planning_application.update!(params, :recommended_application_type)
      end
    end
  end
end
