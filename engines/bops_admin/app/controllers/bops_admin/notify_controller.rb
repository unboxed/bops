# frozen_string_literal: true

module BopsAdmin
  class NotifyController < ApplicationController
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
      @test_message = BopsAdmin::TestMessage.new(test_message_params)

      if @test_message.valid?
        ::SendTestMessageJob.perform_later(
          channel: @test_message.channel,
          template_id: @test_message.template_id,
          email: (@test_message.email if @test_message.channel == "email"),
          phone: (@test_message.phone if @test_message.channel == "sms"),
          personalisation: @test_message.personalisation,
          reply_to_id: current_local_authority.email_reply_to_id.presence,
          local_authority_id: current_local_authority.id
        )

        message = (@test_message.channel == "sms") ?
                    "SMS test queued for #{@test_message.phone}" :
                    "Email test queued for #{@test_message.email}"

        redirect_to main_app.bops_admin_notify_path, status: :see_other, flash: {success: message}
      else
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
        @preview_subject = @letter_preview.personalisation["subject"].presence || "(No subject)"
        @preview_body = @letter_preview.body.presence || "(No body content)"
        render template: "bops_admin/notify/letter_previews/preview"
      end
    end

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

    def resolved_template_id
      params[:sms_template_id].presence || params[:email_template_id].presence
    end

    def send_test_success_message(tm)
      tm.sms? ? "SMS test queued for #{tm.phone}" : "Email test queued for #{tm.email}"
    end

    def letter_preview_params
      params.require(:letter_preview).permit(
        :letter_template_id,
        :sender_name, :sender_department,
        :recipient_name,
        :address_line1, :address_line2, :address_town, :address_postcode,
        :body,
        :personalisation_json
      )
    end

    def use_real_notify_preview?
      Rails.env.production? || Rails.env.staging?
    end

    def resolve_notify_api_key!
      key = current_local_authority.notify_api_key.presence ||
        Rails.configuration.default_notify_api_key.presence
      return key if key.present?
      raise "Notify API key not found"
    end
  end
end
