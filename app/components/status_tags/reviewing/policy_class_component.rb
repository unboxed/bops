# frozen_string_literal: true

module StatusTags
  module Reviewing
    class PolicyClassComponent < StatusTags::BaseComponent
      def initialize(review_policy_class:)
        @review_policy_class = review_policy_class
      end

      private

      def status
        @review_policy_class&.status&.to_sym || :not_started
      end
    end
  end
end
