# frozen_string_literal: true

module StatusTags
  class PermittedDevelopmentRightReviewComponent < StatusTags::BaseComponent
    def initialize(permitted_development_right:)
      @permitted_development_right = permitted_development_right
    end

    private

    attr_reader :permitted_development_right

    def status
      if permitted_development_right.review_complete?
        :complete
      elsif permitted_development_right.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end
  end
end
