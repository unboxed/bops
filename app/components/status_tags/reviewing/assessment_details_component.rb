# frozen_string_literal: true

module StatusTags
  module Reviewing
    class AssessmentDetailsComponent < StatusTags::BaseComponent
      include AssessmentDetailable
      include Recommendable

      def initialize(planning_application:)
        @planning_application = planning_application
        super(status:)
      end

      private

      attr_reader :planning_application

      def status
        if updated?
          :updated
        elsif assessment_details.any?(&:review_in_progress?)
          :in_progress
        elsif review_assessment_details_to_be_reviewed?
          :awaiting_changes
        elsif review_assessment_details_complete?
          :complete
        else
          :not_started
        end
      end

      def updated?
        recommendation_submitted_and_unchallenged? && assessment_details_updated?
      end
    end
  end
end
