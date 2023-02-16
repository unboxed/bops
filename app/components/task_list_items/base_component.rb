# frozen_string_literal: true

module TaskListItems
  class BaseComponent < ViewComponent::Base
    private

    def link_active?
      true
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end
  end
end
