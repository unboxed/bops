# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    class NotifyController < ApplicationController
      helper BopsConfig::Engine.helpers

      before_action :set_local_authority, only: %i[
        edit update
        send_test_new send_test_create
        preview_letter generate_preview
      ]
      before_action :determine_channel!, only: %i[
        send_test_new send_test_create
        preview_letter generate_preview
      ]

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @local_authority.update(local_authority_params, :notify)
            format.html { redirect_to local_authorities_url, notice: t(".success") }
          else
            format.html { render :edit }
          end
        end
      end

      def send_test_new
        @test_message = TestMessage.new(
          channel: @channel,
          template_id: resolved_template_id
        )
        render template: "bops_config/local_authorities/test_messages/new"
      end

      def send_test_create
        @test_message = TestMessage.new(test_message_params)

        unless @test_message.valid?
          return render template: "bops_config/local_authorities/test_messages/new", status: :unprocessable_entity
        end

        client = Notifications::Client.new(@local_authority.notify_api_key)

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

          redirect_to edit_local_authority_notify_path(@local_authority), status: :see_other, flash: {success: flash_message}
        rescue Notifications::Client::AuthError, Notifications::Client::RequestError => e
          Rails.logger.warn("Notify error: #{e.class}: #{e.message}")
          flash.now[:alert] = "Notify error: #{e.message}"
          render template: "bops_config/local_authorities/test_messages/new", status: :unprocessable_entity
        end
      end

      def preview_letter
        @letter_preview = LetterPreview.new(
          {letter_template_id: params[:letter_template_id].to_s.strip.presence}
        )
        render template: "bops_config/local_authorities/letter_previews/new"
      end

      def generate_preview
        @letter_preview = LetterPreview.new(letter_preview_params.to_h)

        @letter_preview.parsed_personalisation
        unless @letter_preview.valid?
          return render template: "bops_config/local_authorities/letter_previews/new", status: :unprocessable_entity
        end

        @personalisation = @letter_preview.personalisation

        if use_real_notify_preview?
          begin
            client = Notifications::Client.new(resolve_notify_api_key!)
            resp = client.generate_template_preview(@letter_preview.letter_template_id,
              personalisation: @letter_preview.personalisation)
            @preview_subject = resp.subject
            @preview_body = resp.body
            render template: "bops_config/local_authorities/letter_previews/preview"
          rescue Notifications::Client::AuthError => e
            flash.now[:alert] = "Notify API key is invalid: #{e.message}"
            render template: "bops_config/local_authorities/letter_previews/new", status: :unprocessable_entity
          rescue Notifications::Client::RequestError => e
            flash.now[:alert] = "Notify error: #{e.message}"
            render template: "bops_config/local_authorities/letter_previews/new", status: :unprocessable_entity
          end
        else
          @preview_subject = @letter_preview.personalisation["heading"].presence || "(No subject)"
          @preview_body = @letter_preview.message.presence || "(No message content)"
          render template: "bops_config/local_authorities/letter_previews/preview"
        end
      end

      private

      def set_local_authority
        @local_authority = LocalAuthority.find_by!(subdomain: params[:local_authority_name])
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
            :email, :phone, :subject, :body, :reply_to_id, personalisation: {})
      end

      def determine_channel!
        @channel = params[:sms_template_id].present? ? "sms" : "email"
      end

      def resolved_template_id
        direct = params[:sms_template_id].presence || params[:email_template_id].presence
        return direct.to_s.strip if direct

        if params[:test_message]
          tm = test_message_params # <- use the full permitted set
          id = tm[:template_id].presence || tm[:sms_template_id].presence || tm[:email_template_id].presence
          return id.to_s.strip if id
        end

        fallback = ((@channel == "sms") ? local_authority.sms_template_id : local_authority.email_template_id)
        fallback.to_s.strip if fallback.present?
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
    end
  end
end
