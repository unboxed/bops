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

    unless message.match?(/\A[A-Z].+\Z/)
      message = "#{attribute.to_s.humanize.tr(".", " ")} #{message}"
    end

    link? ? link_tag(message, attribute) : message
  end

  def attributes_map
    {}
  end

  def link?
    false
  end

  def link_tag(text, attribute)
    raise NotImplementedError, "Subclasses must implement a link_tag(text, attribute) method"
  end
end
