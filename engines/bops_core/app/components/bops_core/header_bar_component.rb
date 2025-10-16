# frozen_string_literal: true

module BopsCore
  class HeaderBarComponent < ViewComponent::Base
    def initialize(left:, right: [], sticky: true)
      @left_items = Array.wrap(left)
      @right_items = Array.wrap(right)
      @sticky = sticky
    end

    private

    attr_reader :left_items, :right_items, :sticky

    def base_link_classes
      "govuk-link"
    end

    def divider_classes
      "bops-header-bar__divider"
    end

    def container_classes
      class_names("bops-header-bar", sticky ? "bops-header-bar--sticky" : "bops-header-bar--static")
    end

    def inner_classes
      "bops-header-bar__inner"
    end

    def left_stack_classes
      "bops-header-bar__left"
    end

    def right_stack_classes
      "bops-header-bar__right"
    end
  end
end
