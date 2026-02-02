# frozen_string_literal: true

module BopsCore
  module Sidebar
    extend ActiveSupport::Concern

    private

    def show_header
      @show_header_bar ||= true
    end

    def show_sidebar
      @show_sidebar ||= @task.top_level_ancestor
    end
  end
end
