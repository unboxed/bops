# frozen_string_literal: true

module BopsConfig
  module ApplicationHelper
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
      page_keys = {
        "dashboard" => "dashboard",
        "users" => "users",
        "application_types" => "application_types",
        "determination_periods" => "application_types",
        "legislation" => "application_types",
        "features" => "application_types",
        "statuses" => "application_types"
      }

      page_keys.fetch(controller_name, "dashboard")
    end

    def nav_items
      [
        {name: "Dashboard", url: root_path, key: "dashboard"},
        {name: "Users", url: users_path, key: "users"},
        {name: "Application types", url: application_types_path, key: "application_types"}
      ]
    end
  end
end
