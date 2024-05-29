# frozen_string_literal: true

class ShowMoreTextComponent < ViewComponent::Base
  def initialize(text:, length: 300)
    @text = text
    @length = length
    @truncated_text = text.truncate(length, separator: " ")
  end

  attr_accessor :text, :length, :truncated_text
end
