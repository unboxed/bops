# frozen_string_literal: true

module StatusTags
  class ReviewComponent < StatusTags::BaseComponent
    def initialize(review_item:, updated: false)
      @review_item = review_item
      @updated = updated
      super(status:)
    end

    attr_reader :review_item, :updated

    private

    def status
      if updated
        :updated
      elsif review_item.nil?
        :not_started
      elsif review_item.review_in_progress?
        :in_progress
      elsif review_item.to_be_reviewed? && review_item.review_complete?
        :awaiting_changes
      elsif review_item.review_complete?
        :complete
      else
        :not_started
      end
    end
  end
end
