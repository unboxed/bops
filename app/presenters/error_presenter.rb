# frozen_string_literal: true

class ErrorPresenter
  def initialize(error_messages, record = nil)
    @error_messages = error_messages
    @record = record
  end

  def formatted_error_messages
    error_messages.map do |attribute, messages|
      [attribute, formatted_message(messages.first, attribute)]
    end
  end

  private

  attr_reader :error_messages, :record

  def formatted_message(message, attribute)
    attribute = attributes_map[attribute] || attribute

    if message.match?(/\A[A-Z].+\Z/)
      message
    else
      text = "#{attribute.to_s.humanize.tr(".", " ")} #{message}"

      link? ? link_tag(text) : text
    end
  end

  def attributes_map
    {}
  end

  def link?
    false
  end
end
