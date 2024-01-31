# frozen_string_literal: true

module StatusTags
  module Reviewing
    class LocalPolicyComponent < StatusTags::BaseComponent
      def initialize(planning_application:, review_local_policy:)
        @planning_application = planning_application
        @review_local_policy = review_local_policy
      end

      private

      attr_reader :planning_application, :review_local_policy

      def status
        if review_local_policy.review_complete?
          :complete
        elsif review_local_policy.in_progress?
          :in_progress
        else
          :not_started
        end
      end
    end
  end
end
