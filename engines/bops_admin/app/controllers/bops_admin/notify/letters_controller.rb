# frozen_string_literal: true

module BopsAdmin
  module Notify
    class LettersController < BaseController
      before_action :redirect_to_notify_page, if: :skip_check?

      def create
        if @letter_form.check
          render :new, notice: t(".success", reference: @letter_form.reference)
        else
          render :new
        end
      end

      private

      def build_form
        @letter_form = BopsCore::Notify::LetterForm.new(current_local_authority, params)
      end

      def skip_check?
        params[:continue] == "true"
      end

      def redirect_to_notify_page
        redirect_to edit_notify_path, notice: "GOV.UK Notify checks completed"
      end
    end
  end
end
