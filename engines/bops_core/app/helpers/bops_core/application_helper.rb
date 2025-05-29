# frozen_string_literal: true

module BopsCore
  module ApplicationHelper
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

    def rich_text_area_tag(name, value = nil, options = {})
      options[:data] ||= {}
      options[:data][:direct_upload_url] ||= bops_uploads.uploads_url
      options[:data][:blob_url_template] ||= bops_uploads.file_url(":key")

      super
    end
  end
end
