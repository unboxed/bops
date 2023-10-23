# frozen_string_literal: true

module TaskListItems
  module Review
    class Component < ViewComponent::Base
      renders_one :link
      renders_one :tag
    end
  end
end
