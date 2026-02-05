# frozen_string_literal: true

module BopsAdmin
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

    def nav_items
      [
        {text: "Dashboard", href: dashboard_path, active: active_page_key?("dashboard")},
        {text: "Applications", href: consultees_path, active: active_page_key?("applications")},
        {text: "Policies", href: policies_path, active: active_page_key?("policies")},
        {text: "Users & Access", href: users_path, active: active_page_key?("users")},
        {text: "Submissions", href: submissions_path, active: active_page_key?("submissions")},
        {text: "Settings", href: profile_path, active: active_page_key?("settings")}
      ]
    end
  end
end
