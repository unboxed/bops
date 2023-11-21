# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  def show
    @user = User.find_by(confirmation_token: params[:confirmation_token])

    render :show
  end

  def confirm_and_set_password
    @user = User.find(user_params[:user_id])

    if @user.update({password: user_params[:password],
                      password_confirmation: user_params[:password_confirmation]})
      @user.confirm

      redirect_to new_user_session_path, notice: "Your email has been confirmed and your password reset. You may now log in"
    else
      render :show, alert: "We were unable to confirm your email. Click below to receive confirmation instructions"
    end
  end

  private

  def user_params
    params.require(:user).permit(:user_id, :password, :password_confirmation, :_method, :authenticity_token, :user, :commit)
  end
end
