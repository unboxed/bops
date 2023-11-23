# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  def show
    @user = User.find_by(confirmation_token: params[:confirmation_token])

    if @user.confirmation_period_expired?
      redirect_to new_user_confirmation_path, alert: t("devise.confirmations.confirmation_expired")
    else
      render :show
    end
  end

  def confirm_and_set_password
    @user = User.find(user_params[:user_id])

    if @user.update({password: user_params[:password],
                      password_confirmation: user_params[:password_confirmation]})
      @user.confirm

      redirect_to new_user_session_path, notice: t("devise.confirmations.confirmed")
    else
      render :show, alert: t("devise.confirmations.failed_confirmation")
    end
  end

  private

  def user_params
    params.require(:user).permit(:user_id, :password, :password_confirmation, :_method, :authenticity_token, :user, :commit)
  end
end
