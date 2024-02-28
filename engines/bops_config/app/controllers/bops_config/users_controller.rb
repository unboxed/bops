# frozen_string_literal: true

module BopsConfig
  class UsersController < ApplicationController
    before_action :set_users, only: %i[index]
    before_action :build_user, only: %i[new create]
    before_action :set_user, only: %i[edit update resend_invite]

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @user.save
          format.html do
            redirect_to users_path, notice: t(".user_successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @user.update(user_params)
          format.html do
            redirect_to users_path, notice: t(".user_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def resend_invite
      respond_to do |format|
        if @user.send_confirmation_instructions
          format.html do
            redirect_to users_path, notice: t(".confirmation_resent")
          end
        else
          format.html do
            redirect_to users_path, alert: t(".confirmation_failed_to_resend")
          end
        end
      end
    end

    private

    def set_users
      @users = user_scope.by_name
    end

    def build_user
      @user = User.new(user_params)
    end

    def set_user
      @user = user_scope.find(params[:id])
    end

    def user_scope
      User.global_administrator
    end

    def user_params
      if action_name == "new"
        {}
      else
        params.require(:user).permit(*user_attributes).merge(role: "global_administrator")
      end
    end

    def user_attributes
      %i[name email otp_delivery_method password mobile_number role]
    end
  end
end
