# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckDescriptionForm < Form
      include BopsCore::Tasks::CheckDescriptionForm

      def redirect_url(options = {})
        if valid_description
          super
        else
          main_app.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "description_change"
          )
        end
      end
    end
  end
end
