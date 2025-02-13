# frozen_string_literal: true

module BopsConfig
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

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

    def active_page_key
      return "legislation" if controller_path == "bops_config/legislation"

      page_keys = {
        "dashboard" => "dashboard",
        "users" => "users",
        "local_authorities" => "local_authorities",
        "application_types" => "application_types",
        "categories" => "application_types",
        "determination_periods" => "application_types",
        "legislation" => "application_types",
        "features" => "application_types",
        "decisions" => "decisions",
        "statuses" => "application_types",
        "reporting_types" => "reporting_types",
        "policy_schedules" => "gpdo",
        "policy_parts" => "gpdo",
        "policy_class" => "gpdo"
      }

      page_keys.fetch(controller_name, "dashboard")
    end

    def nav_items
      [
        {text: "Dashboard", href: root_path, active: active_page_key?("dashboard")},
        {text: "Users", href: users_path, active: active_page_key?("users")},
        {text: "Local authorities", href: local_authorities_path, active: active_page_key?("local_authorities")},
        {text: "Application types", href: application_types_path, active: active_page_key?("application_types")},
        {text: "Legislation", href: legislation_index_path, active: active_page_key?("legislation")},
        {text: "Reporting types", href: reporting_types_path, active: active_page_key?("reporting_types")},
        {text: "Decisions", href: decisions_path, active: active_page_key?("decisions")},
        {text: "GPDO", href: gpdo_policy_schedules_path, active: active_page_key?("gpdo")}
      ]
    end
  end
end
