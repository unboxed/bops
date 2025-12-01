# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteDescriptionForm < BaseForm
      def update(params)
        assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :site_description)

        ActiveRecord::Base.transaction do
          assessment_detail.update!(params)
          if @button == "save_draft"
            task.start!
          else
            task.complete!
          end || raise(ActiveRecord::RecordInvalid)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        @button = params[:button]
        params.require(:task).permit(:entry)
      end
    end
  end
end
