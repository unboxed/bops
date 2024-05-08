# frozen_string_literal: true

module StatusTags
  class ReviewComponent < StatusTags::BaseComponent
    def initialize(review_item:)
      @review_item = review_item
      super(status:)
    end

    attr_reader :review_item

    private

    def status
      if review_item.nil?
        :not_started
      elsif review_item.rejected? || (review_item.to_be_reviewed? && review_item.review_complete?)
        :awaiting_changes
      elsif review_item.review_complete?
        :complete
      elsif review_item.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end
  end
end
