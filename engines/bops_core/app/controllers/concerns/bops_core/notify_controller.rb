# frozen_string_literal: true

module BopsCore
  module NotifyController
    extend ActiveSupport::Concern

    included do
      before_action :determine_channel!, only: %i[send_test_new send_test_create]
      helper BopsAdmin::Engine.helpers
    end

    def edit
      respond_to { |format| format.html }
    end

    def update
      respond_to do |format|
        if local_authority.update(local_authority_params, :notify)
          format.html { redirect_to edit_notify_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    def show
      @local_authority = local_authority
      render :edit
    end

    def send_test_new
      @test_message = BopsAdmin::TestMessage.new(
        channel: @channel,
        template_id: resolved_template_id
      )
      render template: "bops_admin/notify/test_messages/new"
    end

    def send_test_create
      @test_message = BopsAdmin::TestMessage.new(test_message_params)

      unless @test_message.valid?
        return render template: "bops_admin/notify/test_messages/new", status: :unprocessable_entity
      end

      client = Notifications::Client.new(local_authority.notify_api_key)

      begin
        case @test_message.channel
        when "email"
          client.send_email(
            email_address: @test_message.email,
            template_id: resolved_template_id,
            personalisation: @test_message.personalisation.compact
          )
          flash_message = "Email test sent to #{@test_message.email}"
        when "sms"
          client.send_sms(
            phone_number: @test_message.phone,
            template_id: resolved_template_id,
            personalisation: @test_message.personalisation.compact
          )
          flash_message = "SMS test sent to #{@test_message.phone}"
        else
          raise ArgumentError, "Unknown channel: #{@test_message.channel.inspect}"
        end

        redirect_to main_app.bops_admin_notify_path, status: :see_other, flash: {success: flash_message}
      rescue Notifications::Client::AuthError, Notifications::Client::RequestError => e
        Rails.logger.warn("Notify error: #{e.class}: #{e.message}")
        flash.now[:alert] = "Notify error: #{e.message}"
        render template: "bops_admin/notify/test_messages/new", status: :unprocessable_entity
      end
    end

    def preview_letter
      @letter_preview = BopsAdmin::LetterPreview.new(
        {letter_template_id: params[:letter_template_id].to_s.strip.presence}
      )
      render template: "bops_admin/notify/letter_previews/new"
    end

    def generate_preview
      @letter_preview = BopsAdmin::LetterPreview.new(letter_preview_params.to_h)

      @letter_preview.parsed_personalisation
      unless @letter_preview.valid?
        return render template: "bops_admin/notify/letter_previews/new", status: :unprocessable_entity
      end

      @personalisation = @letter_preview.personalisation

      if use_real_notify_preview?
        begin
          client = Notifications::Client.new(resolve_notify_api_key!)
          resp = client.generate_template_preview(@letter_preview.letter_template_id,
            personalisation: @letter_preview.personalisation)
          @preview_subject = resp.subject
          @preview_body = resp.body
          render template: "bops_admin/notify/letter_previews/preview"
        rescue Notifications::Client::AuthError => e
          flash.now[:alert] = "Notify API key is invalid: #{e.message}"
          render template: "bops_admin/notify/letter_previews/new", status: :unprocessable_entity
        rescue Notifications::Client::RequestError => e
          flash.now[:alert] = "Notify error: #{e.message}"
          render template: "bops_admin/notify/letter_previews/new", status: :unprocessable_entity
        end
      else
        @preview_subject = @letter_preview.personalisation["heading"].presence || "(No subject)"
        @preview_body = @letter_preview.message.presence || "(No message content)"
        render template: "bops_admin/notify/letter_previews/preview"
      end
    end

    private

    def local_authority
      current_local_authority.presence || @current_local_authority
    end

    def local_authority_params
      params.require(:local_authority).permit(*local_authority_attributes)
    end

    def local_authority_attributes
      %i[notify_api_key email_reply_to_id email_template_id sms_template_id letter_template_id]
    end

    def test_message_params
      params.require(:test_message)
        .permit(:channel, :template_id, :email_template_id, :sms_template_id,
          :email, :phone, :subject, :body, personalisation: {})
    end

    def determine_channel!
      @channel = params[:sms_template_id].present? ? "sms" : "email"
    end

    def resolved_template_id
      direct = params[:sms_template_id].presence || params[:email_template_id].presence
      return direct if direct.present?

      nested = params.fetch(:test_message, {}).permit(:template_id, :sms_template_id, :email_template_id)

      nested[:template_id].presence ||
        nested[:sms_template_id].presence ||
        nested[:email_template_id].presence ||

        ((@channel == "sms") ? local_authority.sms_template_id : local_authority.email_template_id)
    end

    def letter_preview_params
      params.require(:letter_preview).permit(
        :letter_template_id,
        :address_line_1, :address_line_2, :address_line_3, :address_line_4, :address_line_5, :address_line_6,
        :heading, :message, :personalisation_json
      )
    end

    def use_real_notify_preview?
      Rails.env.production? || Rails.env.staging?
    end

    def resolve_notify_api_key!
      key = local_authority.notify_api_key.presence ||
        Rails.configuration.default_notify_api_key.presence
      return key if key.present?
      raise "Notify API key not found"
    end
  end
end
