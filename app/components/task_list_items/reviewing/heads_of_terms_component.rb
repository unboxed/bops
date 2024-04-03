# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class HeadsOfTermsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate(:heads_of_term, to: :planning_application)

      def link_text
        t(".heads_of_terms")
      end

      def review_heads_of_term
        heads_of_term.current_review
      end

      def link_path
        if review_heads_of_term&.reviewed_at.present? &&
            review_heads_of_term.review_status == "review_complete"
          planning_application_review_heads_of_term_path(
            planning_application,
            review_heads_of_term
          )
        else
          edit_planning_application_review_heads_of_term_path(
            planning_application,
            review_heads_of_term
          )
        end
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if review_heads_of_term&.status == "updated"
          :updated
        else
          review_heads_of_term&.status
        end
      end
    end
  end
end
