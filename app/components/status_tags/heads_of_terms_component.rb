# frozen_string_literal: true

module StatusTags
  class HeadsOfTermsComponent < StatusTags::BaseComponent
    def initialize(heads_of_term:)
      @heads_of_term = heads_of_term
    end

    private

    attr_reader :heads_of_term

    def status
      if heads_of_term.current_review.present?
        if heads_of_term.any_new_updated_validation_requests? && !heads_of_term.current_review.complete?
          "updated"
        else
          heads_of_term.current_review.status.to_sym
        end
      else
        :not_started
      end
    end
  end
end
