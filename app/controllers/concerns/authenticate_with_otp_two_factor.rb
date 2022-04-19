# frozen_string_literal: true

module AuthenticateWithOtpTwoFactor
  extend ActiveSupport::Concern

  def authenticate_with_otp_two_factor
    user = self.resource = find_user

    authenticate_user_with_otp_two_factor(user) if otp_input?

    return unless user&.valid_password?(user_params[:password]) || session[:valid_password]

    save_user_session(user)

    if mobile_number(user)
      send_and_prompt_for_otp_two_factor(user)
    else
      redirect_to setup_path
    end
  end

  private

  def save_user_session(user)
    session[:otp_user_id] = user.id
    session[:valid_password] = true
    session[:mobile_number] = user_params[:mobile_number] if user_params[:mobile_number]
  end

  def send_and_prompt_for_otp_two_factor(user)
    if session[:failed_otp_attempt]
      session.delete(:failed_otp_attempt)
    else
      TwoFactor::SmsNotification.new(mobile_number(user), user.current_otp).deliver!
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
      redirect_to two_factor_path, alert: "Your two factor code is invalid."
    end
  end

  def user_params
    params.require(:user).permit(:email, :mobile_number, :password, :otp_attempt)
  end

  def otp_two_factor_enabled?
    find_user.try(:otp_required_for_login) unless Rails.env.development? && ENV["2FA_ENABLED"] == "true"
  end

  def find_user
    if session[:otp_user_id]
      find_current_local_authority.users.find(session[:otp_user_id])
    elsif user_params[:email]
      find_current_local_authority.users.find_by(email: user_params[:email])
    end
  end

  def mobile_number(user)
    user.try(:mobile_number) || session[:mobile_number]
  end

  def otp_input?
    user_params[:otp_attempt].present? && session[:otp_user_id]
  end

  def find_current_local_authority
    @find_current_local_authority ||= LocalAuthority.find_by(subdomain: request.subdomains.first)
  end
end
