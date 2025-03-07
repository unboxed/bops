# frozen_string_literal: true

module BopsConfig
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    attr_reader :back_path

    PAGE_KEYS = {
      "bops_config/application_types/category" => "application_types",
      "bops_config/application_types/decision_notices" => "application_types",
      "bops_config/application_types/decisions" => "application_types",
      "bops_config/application_types/determination_periods" => "application_types",
      "bops_config/application_types/document_tags" => "application_types",
      "bops_config/application_types/features" => "application_types",
      "bops_config/application_types/legislation" => "application_types",
      "bops_config/application_types/reporting" => "application_types",
      "bops_config/application_types/statuses" => "application_types",
      "bops_config/application_types" => "application_types",
      "bops_config/dashboards" => "dashboard",
      "bops_config/decisions" => "decisions",
      "bops_config/gpdo/policy_class" => "gpdo",
      "bops_config/gpdo/policy_parts" => "gpdo",
      "bops_config/gpdo/policy_schedules" => "gpdo",
      "bops_config/gpdo/policy_sections" => "gpdo",
      "bops_config/legislation" => "legislation",
      "bops_config/local_authorities" => "local_authorities",
      "bops_config/reporting_types" => "reporting_types",
      "bops_config/users" => "users"
    }.freeze

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
      PAGE_KEYS.fetch(controller_path, "dashboard")
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
