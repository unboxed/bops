# frozen_string_literal: true

module BopsReports
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper
    include BopsCore::PlanningDataHelper

    def nav_items
      []
    end

    def home_path
      root_path
    end

    def summary_advice_content(summary_tag)
      I18n.t("summary_advice.#{summary_tag}")
    end

    def map_link(full_address)
      "https://google.co.uk/maps/place/#{CGI.escape(full_address)}"
    end
  end
end
