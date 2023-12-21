# frozen_string_literal: true

module Administrator
  class UsersController < ApplicationController
    before_action :set_user, only: %i[edit update resend_invite]

    def index
      @users = current_local_authority.users
      @confirmed_users = current_local_authority.users.confirmed
      @unconfirmed_users = current_local_authority.users.unconfirmed
    end

    def new
      @user = current_local_authority.users.new
    end

    def edit
    end

    def create
      @user = current_local_authority.users.new(user_params)

      if @user.save
        flash[:notice] = t(
          "administrator.dashboards.show.user_successfully_created"
        )

        redirect_to administrator_users_path
      else
        render :new
      end
    end

    def update
      if @user.update(user_params)
        flash[:notice] = t(
          "administrator.dashboards.show.user_successfully_updated"
        )

        redirect_to administrator_users_path
      else
        render :edit
      end
    end

    def resend_invite
      if @user.send_confirmation_instructions
        flash[:notice] = t(
          "administrator.dashboards.show.confirmation_resent"
        )
        redirect_to administrator_users_path
      end
    end

    private

    def user_params
      params.require(:user).permit(permitted_params).transform_values(&:presence)
    end

    def permitted_params
      %i[name email otp_delivery_method password mobile_number role]
    end

    def set_user
      @user = current_local_authority.users.find(params[:id])
    end
  end
end
