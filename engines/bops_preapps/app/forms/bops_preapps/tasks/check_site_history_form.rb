# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckSiteHistoryForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          planning_application.update!(site_history_checked: true)
          task.update!(status: :completed)
        end
      end

      def permitted_fields(params)
        {} # no params sent: just a submit button
      end
    end
  end
end
