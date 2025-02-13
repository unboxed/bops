# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    rescue_from Notifications::Client::NotFoundError, with: :notify_error
    rescue_from Notifications::Client::ServerError, with: :notify_error
    rescue_from Notifications::Client::RequestError, with: :notify_error
    rescue_from Notifications::Client::ClientError, with: :notify_error
    rescue_from Notifications::Client::BadRequestError, with: :notify_error

    include AuthenticateWithOtpTwoFactor

    skip_before_action :enforce_user_permissions

    before_action :authenticate_with_otp_two_factor, only: %i[create]
    before_action :find_otp_user, only: %i[setup two_factor resend_code]
    before_action :set_mobile_number_form, only: %i[setup two_factor]

    protect_from_forgery with: :exception, prepend: true, except: :destroy

    def create
      super
    end

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

    def set_mobile_number_form
      @mobile_number_form = MobileNumberForm.new
    end

    def find_otp_user
      @user = user_scope.find_by(id: session[:otp_user_id])

      redirect_to root_path unless @user
    end

    def can_resend_code?
      session[:last_code_sent_at] && session[:last_code_sent_at] > (1.minute.ago)
    end

    def notify_error(exception)
      Appsignal.report_error(exception)

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
