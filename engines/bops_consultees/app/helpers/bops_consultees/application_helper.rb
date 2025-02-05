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

    def link_to_document(link_text, document, **args)
      new_tab = /(new (window|tab)|<img\b)/.match?(link_text) ? "" : true

      govuk_link_to(
        link_text,
        planning_application_document_path(document.planning_application, document),
        new_tab:,
        **args
      )
    end
  end
end
