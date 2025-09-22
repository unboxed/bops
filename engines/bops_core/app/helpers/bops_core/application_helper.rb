# frozen_string_literal: true

module BopsCore
  module ApplicationHelper
    include ApplicationTypeHelper
    include TasksHelper
    include GOVUKDesignSystemFormBuilder::BuilderHelper

    using HTMLAttributesUtils

    {
      bops_secondary_navigation: "BopsCore::SecondaryNavigationComponent",
      bops_side_navigation: "BopsCore::SideNavigationComponent",
      bops_sub_navigation: "BopsCore::SubNavigationComponent",
      bops_task_accordion: "BopsCore::TaskAccordionComponent",
      bops_ticket_panel: "BopsCore::TicketPanelComponent",
      bops_status_detail: "BopsCore::StatusDetailComponent",
      bops_notification_banner: "BopsCore::NotificationBannerComponent"
    }.each do |name, klass|
      define_method(name) do |*args, **kwargs, &block|
        capture do
          render(klass.constantize.new(*args, **kwargs)) do |com|
            block.call(com) if block.present?
          end
        end
      end
    end

    def govuk_button(content = nil, name: nil, type: "button", **html_attributes, &)
      default_attributes = {
        type: type,
        class: "govuk-button",
        data: {module: "govuk-button"}
      }

      options = default_attributes
        .deep_merge_html_attributes(html_attributes)
        .deep_tidy_html_attributes

      # The deep_tidy_html_attributes removes blank attributes
      # so we need to add the 'name' attribute afterwards.
      options[:name] = name

      button_tag(content, options, &)
    end

    def active_page_key?(page_key)
      active_page_key == page_key
    end

    def markdown(text)
      return if text.blank?

      CommonMarker.render_html(text).html_safe
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

    def role_name
      if current_user.assessor?
        "Case Officer"
      elsif current_user.reviewer?
        "Manager"
      end
    end

    def active_page_key
      page_keys = {
        "planning_applications" => "planning_applications",
        "enforcements" => "enforcements"
      }

      page_keys.fetch(controller_name, "dashboard")
    end

    def nav_items
      return [] unless current_user

      [
        {text: "Planning", href: main_app.planning_applications_path, active: active_page_key?("planning_applications")},
        {text: "Enforcement", href: bops_enforcements.enforcements_path, active: active_page_key?("enforcements")}
      ]
    end
  end
end
