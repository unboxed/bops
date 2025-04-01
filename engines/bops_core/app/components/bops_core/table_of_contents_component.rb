# frozen_string_literal: true

class BopsCore::TableOfContentsComponent < ViewComponent::Base
  def initialize(items:)
    @items = items
  end

  attr_reader :items
end
