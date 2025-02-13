# frozen_string_literal: true

module AuthenticateWithOtpTwoFactor
  extend ActiveSupport::Concern

  def authenticate_with_otp_two_factor
    return unless otp_two_factor_enabled?
    return unless valid_mobile_number?

    user = self.resource = find_user

    authenticate_user_with_otp_two_factor(user) if otp_input?

    return unless user&.valid_password?(user_params[:password]) || session[:valid_password]

    save_user_session(user)

    if mobile_number_needed?(user)
      redirect_to setup_path
    else
      send_and_prompt_for_otp_two_factor(user)
    end
  end

  private

  def valid_mobile_number?
    return true unless user_params.key?("mobile_number")

    @mobile_number_form = MobileNumberForm.new(user_params)
    return true if @mobile_number_form.valid?

    render "devise/sessions/setup" and return false
  end

  def save_user_session(user)
    session[:otp_user_id] = user.id
    session[:valid_password] = true
    session[:mobile_number] = user_params[:mobile_number] if user_params[:mobile_number]
  end

  def send_and_prompt_for_otp_two_factor(user)
    if session[:failed_otp_attempt]
      session.delete(:failed_otp_attempt)
    else
      user.send_otp(session[:mobile_number])
      session[:last_code_sent_at] = Time.current

      redirect_to two_factor_path
    end
  end

  def authenticate_user_with_otp_two_factor(user)
    if user.valid_otp_attempt?(user_params[:otp_attempt])
      session.delete(:otp_user_id)
      session.delete(:valid_password)

      user.save!
      sign_in(user, event: :authentication)
    else
      session[:failed_otp_attempt] = true
      redirect_to two_factor_path, alert: t(".two_factor_invalid")
    end
  end

  def user_params
    params.require(:user).permit(:email, :mobile_number, :password, :otp_attempt)
  end

  def otp_two_factor_enabled?
    find_user.try(:otp_required_for_login)
  end

  def find_user
    if session[:otp_user_id]
      user_scope.find(session[:otp_user_id])
    elsif user_params[:email]
      user_scope.find_for_authentication(email: user_params[:email])
    end
  end

  def user_scope
    request.env["bops.user_scope"]
  end

  def mobile_number_needed?(user)
    user.send_otp_by_sms? && mobile_number(user).blank?
  end

  def mobile_number(user)
    user.try(:mobile_number).presence || session[:mobile_number]
  end

  def otp_input?
    user_params[:otp_attempt].present? && session[:otp_user_id]
  end
end
