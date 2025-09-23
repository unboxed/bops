# frozen_string_literal: true

module BopsAdmin
  module Notify
    class SmsController < BaseController
      before_action :redirect_to_letter_check, if: :skip_check?

      def create
        if @sms_form.check
          render :new, notice: t(".success", reference: @sms_form.reference)
        else
          render :new
        end
      end

      private

      def build_form
        @sms_form = BopsCore::Notify::SmsForm.new(current_local_authority, params)
      end

      def skip_check?
        params[:continue] == "true"
      end

      def redirect_to_letter_check
        redirect_to new_notify_letter_url
      end
    end
  end
end
