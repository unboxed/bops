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
        elsif review_assessment_details_complete?
          :complete
        elsif assessment_details.any?(&:reviewer_verdict)
          :in_progress
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
