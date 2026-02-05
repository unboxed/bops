# frozen_string_literal: true

module BopsCore
  module ApplicationHelper
    include ApplicationTypeHelper
    include AssetsHelper
    include BopsCore::PlanningDataHelper
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

    def active_page_key?(key)
      page_key == key
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
        "Reviewer"
      end
    end

    def nav_items
      return [] unless current_user
      return [] unless @show_section_navigation
      [
        {text: "Pre-application", href: preapp_home_path, active: active_page_key?("pre_applications")},
        {text: "Planning", href: home_path, active: active_page_key?("planning_applications")},
        {text: "Enforcement", href: enforcements_home_path, active: active_page_key?("enforcements")}
      ]
    end

    def home_path
      main_app.root_path
    end

    def enforcements_home_path
      bops_enforcements.enforcements_path
    end

    def preapp_home_path
      bops_preapps.root_path
    end

    def map_link(full_address)
      "https://google.co.uk/maps/place/#{CGI.escape(full_address)}"
    end

    def show_map_pin?(caseable, data)
      (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) && caseable.lonlat.present?
    end

    def summary_tag_label(summary_tag)
      return unless summary_tag
      label = t("helpers.summary_tags.#{summary_tag}", default: summary_tag.titleize)
      css_class =
        case summary_tag
        when "complies"
          "govuk-tag govuk-tag--green"
        when "needs_changes"
          "govuk-tag govuk-tag--yellow"
        when "does_not_comply"
          "govuk-tag govuk-tag--red"
        else
          "govuk-tag govuk-tag--grey"
        end

      content_tag(:span, label, class: css_class)
    end

    def return_to_hidden_field
      return if params[:return_to].blank?

      hidden_field_tag :return_to, params[:return_to]
    end
  end
end
