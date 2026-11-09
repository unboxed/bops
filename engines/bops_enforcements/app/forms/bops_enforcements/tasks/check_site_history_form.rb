# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckSiteHistoryForm < Form
      attribute :details, :string

      after_initialize do
        @site_history = enforcement.site_history
        self.details ||= site_history.details
      end
      attr_reader :site_history

      private

      def save_and_complete
        super do
          site_history.update!(details:, activity_date: Time.zone.now)
        end
      end
    end
  end
end
