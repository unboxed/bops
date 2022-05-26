# frozen_string_literal: true

class ErrorPresenter
  def initialize(error_messages)
    @error_messages = error_messages
  end

  def formatted_error_messages
    error_messages.map do |attribute, messages|
      [attribute, "#{attribute.to_s.humanize} #{messages.first}"]
    end
  end

  private

  attr_reader :error_messages
end
