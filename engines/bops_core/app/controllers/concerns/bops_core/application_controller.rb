# frozen_string_literal: true

module BopsCore
  module ApplicationController
    extend ActiveSupport::Concern

    include Pagy::Backend

    included do
      before_action :set_current
      before_action :set_appsignal_tags

      class_attribute :page_key, instance_writer: false, default: "dashboard"

      helper_method :current_local_authority
      helper_method :page_key
    end

    def render(options = {}, locals = {}, &)
      flash_options = (Hash === options) ? options : locals

      self.class._flash_types.each do |flash_type|
        if (value = flash_options.delete(flash_type))
          flash.now[flash_type] = value
        end
      end

      if (other_flashes = flash_options.delete(:flash))
        other_flashes.each do |key, value|
          flash.now[key] = value
        end
      end

      super
    end

    private

    def current_local_authority
      return @current_local_authority if defined?(@current_local_authority)
      @current_local_authority = request.env["bops.local_authority"]
    end

    def require_local_authority!
      unless devise_controller? || current_local_authority
        raise ActiveRecord::RecordNotFound, "Couldn't find LocalAuthority with 'subdomain'=#{request.subdomains.first}"
      end
    end

    def require_administrator!
      unless current_user.administrator?
        redirect_to main_app.root_url, alert: t("bops_admin.administrator_required", path: request.path)
      end
    end

    def require_global_administrator!
      unless current_user.global_administrator?
        redirect_to main_app.root_url
      end
    end

    def require_assessor!
      unless current_user.assessor?
        redirect_to main_app.root_url
      end
    end

    def require_reviewer!
      unless current_user.reviewer?
        redirect_to main_app.root_url
      end
    end

    def authenticate_api_user
      return nil unless current_local_authority

      authenticate_with_http_token do |token, options|
        current_local_authority.api_users.authenticate(token)
      end
    end

    def current_api_user
      return @current_api_user if defined?(@current_api_user)
      @current_api_user = authenticate_api_user
    end

    def authenticate_api_user!
      unless current_api_user && valid_api_key_scope?(current_api_user)
        json = {error: {code: 401, message: "Unauthorized"}}
        render json: json, status: :unauthorized
      end
    end

    def valid_api_key_scope?(key)
      scope_type = if request.method == "GET"
        ":read"
      else
        ":write"
      end

      raise NotImplementedError, "No permissions have been defined for this authenticated method for #{params[:controller]}:#{request.method}" if required_api_key_scope.nil?

      required_api_key_scope == :any || key.permits?(required_api_key_scope + scope_type)
    end

    def set_current
      Current.local_authority = current_local_authority
      Current.user = current_user
      Current.api_user = current_api_user
    end

    def set_appsignal_tags
      tags = {}

      if current_local_authority
        tags[:local_authority] = current_local_authority.subdomain
      end

      if current_user
        tags[:user_id] = current_user.id
      end

      if current_api_user
        tags[:api_user_id] = current_api_user.id
      end

      Appsignal.add_tags(tags)
    end

    def set_back_path
      session[:back_path] = request.referer if request.get?
      @back_path = session[:back_path]
    end

    def reset_session_and_redirect(_exception = nil)
      reset_session

      redirect_to request.referer || "/"
    end
  end
end
