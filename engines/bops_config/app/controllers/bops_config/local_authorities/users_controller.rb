# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    class UsersController < ApplicationController
      self.page_key = "local_authorities"

      before_action :set_local_authority

      include BopsCore::UserManagement

      private

      def set_local_authority
        @local_authority = LocalAuthority.find_by!(subdomain: params[:local_authority_name])
      end

      def users_redirect_path
        local_authority_users_path(@local_authority)
      end

      def user_scope
        @local_authority.users
      end

      def build_user_scope
        @local_authority.users
      end

      def user_attributes
        %i[name email otp_delivery_method mobile_number role]
      end
    end
  end
end
