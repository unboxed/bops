# frozen_string_literal: true

module AccordionSections
  class FeedbackComponent < ViewComponent::Base
    def initialize(feedback:, warning_message:)
      @feedback = feedback
      @warning_message = warning_message
    end

    def render?
      feedback.present?
    end

    private

    attr_reader :feedback, :warning_message
  end
end
