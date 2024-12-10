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

    def active_page_key
      case controller_name
      when "dashboard"
        "dashboard"
      when "settings", "determination_periods"
        "setting"
      when "tokens"
        "tokens"
      when "users"
        "users"
      when "consultees"
        "consultees"
      when "profiles"
        "profile"
      when "informatives"
        "informatives"
      when "policy_areas", "policy_guidance", "policy_references"
        "policy"
      else
        "dashboard"
      end
    end

    def nav_items
      [
        {link: {text: "Dashboard", href: root_path}, current: active_page_key?("dashboard")},
        {link: {text: "Application settings", href: setting_path}, current: active_page_key?("setting")},
        {link: {text: "Consultees", href: consultees_path}, current: active_page_key?("consultees")},
        {link: {text: "Informatives", href: informatives_path}, current: active_page_key?("informatives")},
        {link: {text: "Policy", href: policy_root_path}, current: active_page_key?("policy")},
        {link: {text: "Users", href: users_path}, current: active_page_key?("users")},
        {link: {text: "API tokens", href: tokens_path}, current: active_page_key?("tokens")},
        {link: {text: "Profile", href: profile_path}, current: active_page_key?("profile")}
      ]
    end
  end
end
