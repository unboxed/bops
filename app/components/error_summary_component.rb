# frozen_string_literal: true

class ErrorSummaryComponent < ViewComponent::Base
  def initialize(errors:, full_messages: false)
    @errors = errors
    @full_messages = full_messages
  end

  attr_reader :errors

  def title
    "There is a problem"
  end

  def error_messages
    @full_messages ? @errors.full_messages : @errors.map(&:message)
  end
end
