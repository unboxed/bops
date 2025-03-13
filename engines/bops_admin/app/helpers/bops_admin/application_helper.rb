# frozen_string_literal: true

module BopsAdmin
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    DASHBOARD_PAGES = %w[dashboards].freeze
    APPLICATION_PAGES = %w[consultees].freeze
    POLICY_PAGES = %w[informatives policy_areas policy_guidances policy_references].freeze
    USER_PAGES = %w[tokens users].freeze
    SETTING_PAGES = %w[application_types profiles].freeze

    attr_reader :back_path

    def back_link(classname: "govuk-button govuk-button--secondary")
      link_to(t("back"), back_path, class: classname)
    end

    def home_path
      main_app.root_path
    end

    def otp_delivery_method_options
      User.otp_delivery_methods.keys.map { |key| [key, t(".#{key}")] }
    end

    def dashboard_page?(page)
      DASHBOARD_PAGES.include?(page)
    end

    def application_page?(page)
      APPLICATION_PAGES.include?(page)
    end

    def policy_page?(page)
      POLICY_PAGES.include?(page)
    end

    def user_page?(page)
      USER_PAGES.include?(page)
    end

    def setting_page?(page)
      SETTING_PAGES.include?(page)
    end

    def active_page_key
      if dashboard_page?(controller_name)
        "dashboard"
      elsif application_page?(controller_name)
        "applications"
      elsif policy_page?(controller_name)
        "policies"
      elsif user_page?(controller_name)
        "users"
      elsif setting_page?(controller_name)
        "settings"
      else
        ""
      end
    end

    def nav_items
      [
        {text: "Dashboard", href: dashboard_path, active: active_page_key?("dashboard")},
        {text: "Applications", href: consultees_path, active: active_page_key?("applications")},
        {text: "Policies", href: policies_path, active: active_page_key?("policies")},
        {text: "Users & Access", href: users_path, active: active_page_key?("users")},
        {text: "Settings", href: profile_path, active: active_page_key?("settings")}
      ]
    end
  end
end
