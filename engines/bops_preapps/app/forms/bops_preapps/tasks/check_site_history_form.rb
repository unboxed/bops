# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckSiteHistoryForm < BaseForm
      def update(params)
        if params[:button] == "save_draft"
          task.start!
        else
          ActiveRecord::Base.transaction do
            planning_application.update!(site_history_checked: true)
            task.complete!
          end
        end
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def permitted_fields(params)
        params # no params sent: just a submit button
      end
    end
  end
end
