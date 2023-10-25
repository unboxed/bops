# frozen_string_literal: true

module Reviewing
  module Tasks
    class ButtonGroupComponent < ViewComponent::Base
      def initialize(planning_application:)
        @planning_application = planning_application
        @challenged = planning_application&.recommendation&.challenged
      end

      private

      def render_publish_button?
        @planning_application.recommendation_review_complete? && unchallenged?
      end

      def unchallenged?
        @challenged == false
      end
    end
  end
end
