# frozen_string_literal: true

class ShowMoreTextComponent < ViewComponent::Base
  def initialize(text:, other_text: nil, title: nil, other_text_title: nil, length: 300)
    @text = text
    @other_text = other_text
    @title = title
    @other_text_title = other_text_title
    @length = length
    @truncated_text = all_text.truncate(length, separator: " ")
  end

  attr_reader :text, :other_text, :title, :other_text_title, :length, :truncated_text

  private

  def all_text
    other_text.present? ? "#{text}\n\n<strong>#{other_text_title}:</strong> #{other_text}" : text
  end
end
