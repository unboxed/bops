# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    rescue_from Notifications::Client::NotFoundError, with: :notify_error
    rescue_from Notifications::Client::ServerError, with: :notify_error
    rescue_from Notifications::Client::RequestError, with: :notify_error
    rescue_from Notifications::Client::ClientError, with: :notify_error
    rescue_from Notifications::Client::BadRequestError, with: :notify_error

    include AuthenticateWithOtpTwoFactor

    before_action :find_current_local_authority_from_subdomain
    prepend_before_action :authenticate_with_otp_two_factor, if: :otp_two_factor_enabled?, only: :create
    before_action :find_otp_user, only: %i[setup two_factor resend_code]
    skip_before_action :enforce_user_permissions

    protect_from_forgery with: :exception, prepend: true, except: :destroy

    def setup
      render "devise/sessions/new" if @user.mobile_number?

      respond_to do |format|
        format.html
      end
    end

    def two_factor
      render "devise/sessions/setup" if mobile_number_needed?(@user)

      respond_to do |format|
        format.html
      end
    end

    def resend_code
      if can_resend_code?
        flash.now[:alert] = "Please wait at least a minute before resending your verification code."
      else
        @user.send_otp(session[:mobile_number])
        session[:last_code_sent_at] = Time.current
        flash.now[:notice] = "You have been sent another verification code."
      end

      render "devise/sessions/two_factor"
    end

    private

    def find_otp_user
      @user = find_current_local_authority.users.find_by(id: session[:otp_user_id])

      redirect_to root_path unless @user
    end

    def can_resend_code?
      session[:last_code_sent_at] && session[:last_code_sent_at] > (1.minute.ago)
    end

    def notify_error(exception)
      Appsignal.send_error(exception)

      session.delete(:mobile_number)

      respond_to do |format|
        format.html do
          redirect_to two_factor_path,
                      alert: "Notify was unable to send sms with error: #{exception.message}."
        end
      end
    end
  end
end
