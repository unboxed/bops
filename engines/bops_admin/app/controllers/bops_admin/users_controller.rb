# frozen_string_literal: true

module BopsAdmin
  class UsersController < AccessController
    include BopsCore::UserManagement

    private

    def users_redirect_path
      users_path
    end

    def user_scope
      current_local_authority.users
    end

    def build_user_scope
      current_local_authority.users
    end

    def user_attributes
      %i[name email otp_delivery_method mobile_number role]
    end
  end
end
