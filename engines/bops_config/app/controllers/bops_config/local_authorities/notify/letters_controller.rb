# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    module Notify
      class LettersController < BaseController
        before_action :redirect_to_local_authority_page, if: :skip_check?

        def create
          if @letter_form.check
            render :new, notice: t(".success", reference: @letter_form.reference)
          else
            render :new
          end
        end

        private

        def build_form
          @letter_form = BopsCore::Notify::LetterForm.new(@local_authority, params)
        end

        def skip_check?
          params[:continue] == "true"
        end

        def redirect_to_local_authority_page
          redirect_to edit_local_authority_notify_url(@local_authority), notice: "GOV.UK Notify checks completed"
        end
      end
    end
  end
end
