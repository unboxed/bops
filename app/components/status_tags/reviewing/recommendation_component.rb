# frozen_string_literal: true

module StatusTags
  module Reviewing
    class RecommendationComponent < StatusTags::BaseComponent
      include AssessmentDetailable
      include PermittedDevelopmentRightable
      include Recommendable

      def initialize(planning_application:, user:)
        @planning_application = planning_application
        @user = user
      end

      private

      attr_reader :planning_application, :user

      delegate(:permitted_development_right, to: :planning_application)

      def status
        if planning_application.recommendation_review_complete?
          :complete
        else
          send(:"#{user.role}_status")
        end
      end

      def reviewer_status
        return unless planning_application.awaiting_determination?

        if updated?
          :updated
        elsif planning_application.review_in_progress?
          :in_progress
        else
          :not_started
        end
      end

      def assessor_status
        :awaiting_determination if planning_application.awaiting_determination?
      end

      def updated?
        recommendation_submitted_and_unchallenged? &&
          (permitted_development_right_updated? || assessment_details_updated?)
      end
    end
  end
end
