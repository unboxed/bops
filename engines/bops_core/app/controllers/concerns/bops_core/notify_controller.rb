# frozen_string_literal: true

module BopsCore
  module NotifyController
    extend ActiveSupport::Concern

    private

    def local_authority_params
      params.require(:local_authority).permit(*local_authority_attributes)
    end

    def local_authority_attributes
      %i[notify_api_key email_reply_to_id email_template_id sms_template_id letter_template_id]
    end

    def test_message_params
      params.require(:test_message).permit(:channel, :template_id, :email, :phone, :subject, :body)
    end

    def determine_channel!
      @channel =
        if params[:sms_template_id].present?
          "sms"
        elsif params[:email_template_id].present?
          "email"
        else
          "email"
        end
    end

    def letter_preview_params
      params.require(:letter_preview).permit(
        :letter_template_id,
        :address_line_1, :address_line_2, :address_line_3, :address_line_4, :address_line_5, :address_line_6,
        :heading,
        :message,
        :personalisation_json
      )
    end

    def use_real_notify_preview?
      Rails.env.production? || Rails.env.staging?
    end
  end
end
