# frozen_string_literal: true

class BopsCore::TableOfContentsComponent < ViewComponent::Base
  def initialize(sections:)
    @sections = sections
  end

  attr_reader :sections
end
