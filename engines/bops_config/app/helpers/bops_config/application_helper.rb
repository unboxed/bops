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
      case controller_name
      when "dashboard"
        "dashboard"
      when "users"
        "users"
      when "application_types"
        "application_types"
      when "determination_periods"
        "application_types"
      when "legislation"
        "application_types"
      else
        "dashboard"
      end
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
