# frozen_string_literal: true

module BopsConsultees
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    def nav_items
      []
    end

    def home_path
      root_path
    end
  end
end
