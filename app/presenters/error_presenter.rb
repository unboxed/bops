# frozen_string_literal: true

class ErrorPresenter
  def initialize(error_messages)
    @error_messages = error_messages
  end

  def formatted_error_messages
    error_messages.map do |attribute, messages|
      [attribute, formatted_message(messages.first, attribute)]
    end
  end

  private

  attr_reader :error_messages

  def formatted_message(message, attribute)
    attribute = attributes_map[attribute] || attribute

    if message.match?(/\A[A-Z].+\Z/)
      message
    else
      "#{attribute.to_s.humanize} #{message}"
    end
  end

  def attributes_map
    {}
  end
end
