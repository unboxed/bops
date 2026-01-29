# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    class NotifyController < ApplicationController
      self.page_key = "local_authorities"

      before_action :set_local_authority, only: %i[edit update]

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @local_authority.update(local_authority_params, :notify)
            format.html { redirect_to after_update_success_url, notice: t(".success") }
          else
            format.html { render :edit }
          end
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
        %i[notify_api_key email_reply_to_id email_template_id sms_template_id letter_template_id enable_notify]
      end

      def check_settings?
        params[:check_settings] == "true"
      end

      def after_update_success_url
        if check_settings?
          new_local_authority_notify_email_url(@local_authority)
        else
          local_authorities_url
        end
      end
    end
  end
end
