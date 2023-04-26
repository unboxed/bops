# frozen_string_literal: true

module StatusTags
  class ImmunityDetailReviewComponent < StatusTags::BaseComponent
    def initialize(planning_application:, review_immunity_detail:)
      @planning_application = planning_application
      @review_immunity_detail = review_immunity_detail
    end

    private

    attr_reader :planning_application, :review_immunity_detail

    def status
      if review_immunity_detail.reviewed_at.present? &&
         review_immunity_detail.immunity_detail.review_status == "review_complete"
        :complete
      elsif review_immunity_detail.reviewed_at.present? &&
            review_immunity_detail.immunity_detail.review_status == "review_in_progress"
        :in_progress
      else
        :not_started
      end
    end
  end
end
