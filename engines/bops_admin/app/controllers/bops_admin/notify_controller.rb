# frozen_string_literal: true

module BopsAdmin
  class NotifyController < ApplicationController
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(local_authority_params, :notify)
          format.html { redirect_to after_update_success_url, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def local_authority_params
      params.require(:local_authority).permit(*local_authority_attributes)
    end

    def local_authority_attributes
      %i[notify_api_key email_reply_to_id email_template_id sms_template_id letter_template_id]
    end

    def check_settings?
      params[:check_settings] == "true"
    end

    def after_update_success_url
      if check_settings?
        new_notify_email_url
      else
        edit_notify_path
      end
    end
  end
end
