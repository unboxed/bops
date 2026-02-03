# frozen_string_literal: true

module BopsConfig
  class UsersController < ApplicationController
    self.page_key = "users"

    include BopsCore::UserManagement

    private

    def users_redirect_path
      users_path
    end

    def user_scope
      User.global_administrator
    end

    def build_user_scope
      User.global_administrator
    end

    def user_attributes
      %i[name email otp_delivery_method mobile_number]
    end
  end
end
