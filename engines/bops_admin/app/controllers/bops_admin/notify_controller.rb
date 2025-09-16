# frozen_string_literal: true

module BopsAdmin
  class NotifyController < ApplicationController
    include BopsCore::NotifyController

    before_action :determine_channel!, only: %i[send_test_new send_test_create]
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(local_authority_params, :notify)
          format.html { redirect_to edit_notify_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    def show
      @local_authority = current_local_authority
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
      @test_message = TestMessage.new(test_message_params)

      unless @test_message.valid?
        return render template: "bops_admin/notify/test_messages/new", status: :unprocessable_entity
      end

      client = Notifications::Client.new(current_local_authority.notify_api_key)

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

        redirect_to edit_notify_path(@local_authority), status: :see_other, flash: {success: flash_message}
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

    def resolved_template_id
      current_local_authority.sms_template_id.presence || current_local_authority.letter_template_id.presence
    end

    def resolve_notify_api_key!
      key = current_local_authority.notify_api_key.presence ||
        Rails.configuration.default_notify_api_key.presence
      return key if key.present?
      raise "Notify API key not found"
    end
  end
end
