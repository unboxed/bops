# frozen_string_literal: true

module Reviewing
  module PlanningApplicationPolicyClass
    class LinkComponent < ViewComponent::Base
      erb_template <<~ERB
        <%= govuk_link_to(link_text, link_path, aria: {describedby: link_text}) %>
      ERB

      def initialize(planning_application_policy_class:)
        @planning_application_policy_class = planning_application_policy_class
        @planning_application = planning_application_policy_class.planning_application
        @policy_class = planning_application_policy_class.policy_class
        @part = @policy_class.policy_part
      end

      attr_reader :planning_application, :planning_application_policy_class, :policy_class, :part

      def link_path
        case planning_application_policy_class.current_review.review_status
        when "review_complete"
          planning_application_review_policy_areas_policy_class_path(planning_application_policy_class.planning_application, planning_application_policy_class)
        else
          edit_planning_application_review_policy_areas_policy_class_path(
            planning_application, planning_application_policy_class
          )
        end
      end

      def link_text
        "Review assessment of Part #{part.number}, Class #{policy_class.section}"
      end
    end
  end
end
