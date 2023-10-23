# frozen_string_literal: true

module StatusTags
  module Review
    class ImmunityEnforcementComponent < StatusTags::BaseComponent
      def initialize(planning_application:, review_immunity_detail:)
        @planning_application = planning_application
        @review_immunity_detail = review_immunity_detail
      end

      private

      attr_reader :planning_application, :review_immunity_detail

      def status
        if review_immunity_detail.review_complete?
          :complete
        elsif review_immunity_detail.review_in_progress?
          :in_progress
        else
          :not_started
        end
      end
    end
  end
end
