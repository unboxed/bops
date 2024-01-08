# frozen_string_literal: true

class TabsComponent < ViewComponent::Base
  def initialize(partial:, tabs:, collection_key:)
    @partial = partial
    @tabs = tabs
    @collection_key = collection_key
  end

  private

  attr_reader :partial, :collection_key

  def render_tab(tab)
    render(partial, collection_key => tab[:records])
  end
end
