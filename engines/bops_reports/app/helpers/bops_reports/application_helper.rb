# frozen_string_literal: true

module BopsReports
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper
    include PlanningDataHelper

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

    def link_to_document(link_text, document, **args)
      new_tab = /(new (window|tab)|<img\b)/.match?(link_text) ? "" : true

      govuk_link_to(
        link_text,
        url_for_document(document),
        new_tab:,
        **args
      )
    end

    def url_for_document(document)
      if document.published?
        main_app.api_v1_planning_application_document_url(document.planning_application, document)
      else
        main_app.uploaded_file_url(document.blob)
      end
    end
  end
end
