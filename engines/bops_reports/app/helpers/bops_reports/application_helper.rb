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

    def summary_advice_content(summary_tag)
      I18n.t("summary_advice.#{summary_tag}")
    end
  end
end
