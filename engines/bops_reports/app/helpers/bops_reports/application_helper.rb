# frozen_string_literal: true

module BopsReports
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
