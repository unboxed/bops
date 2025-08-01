# frozen_string_literal: true

module BopsEnforcements
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    def home_path
      root_path
    end
  end
end
