# frozen_string_literal: true

module StatusTags
  class ImmunityDetailReviewComponent < StatusTags::BaseComponent
    include ImmunityDetailRightable
    include Recommendable

    def initialize(planning_application:, immunity_detail:)
      @planning_application = planning_application
      @immunity_detail = immunity_detail
    end

    private

    attr_reader :planning_application, :immunity_detail

    def status
      if updated?
        :updated
      elsif immunity_detail.review_complete?
        :complete
      elsif immunity_detail.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end

    def updated?
      recommendation_submitted_and_unchallenged? &&
      immunity_detail_updated?
    end
  end
end
