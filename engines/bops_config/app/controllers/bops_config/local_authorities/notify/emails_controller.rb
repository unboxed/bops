# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    module Notify
      class EmailsController < BaseController
        before_action :redirect_to_sms_check, if: :skip_check?

        def create
          if @email_form.check
            render :new, notice: t(".success", reference: @email_form.reference)
          else
            render :new
          end
        end

        private

        def build_form
          @email_form = BopsCore::Notify::EmailForm.new(@local_authority, params)
        end

        def skip_check?
          params[:continue] == "true"
        end

        def redirect_to_sms_check
          redirect_to new_local_authority_notify_sms_url(@local_authority)
        end
      end
    end
  end
end
