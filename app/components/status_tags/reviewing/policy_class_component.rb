# frozen_string_literal: true

module StatusTags
  module Reviewing
    class PolicyClassComponent < StatusTags::BaseComponent
      def initialize(review_policy_class:)
        @review_policy_class = review_policy_class
      end

      private

      def status
        if @review_policy_class&.status == "updated"
          :updated
        else
          @review_policy_class&.review_status&.to_sym
        end
      end
    end
  end
end
