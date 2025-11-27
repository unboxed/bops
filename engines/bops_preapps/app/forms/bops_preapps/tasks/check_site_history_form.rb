# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckSiteHistoryForm < BaseForm
      def update(params)
        if params[:button] == "save_draft"
          task.start!
        else
          begin
            ActiveRecord::Base.transaction do
              planning_application.update!(site_history_checked: true)
              task.complete! || raise(ActiveRecord::RecordInvalid)
            end
          rescue ActiveRecord::RecordInvalid
            false
          end
        end
      end

      def permitted_fields(params)
        params # no params sent: just a submit button
      end
    end
  end
end
