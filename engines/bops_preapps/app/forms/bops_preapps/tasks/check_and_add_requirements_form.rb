# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndAddRequirementsForm < BaseForm
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
