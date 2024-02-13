# frozen_string_literal: true

module BopsAdmin
  class ProfilesController < ApplicationController
    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @local_authority.update(local_authority_params)
          format.html do
            redirect_to profile_path, notice: t(".profile_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def local_authority_params
      params.require(:local_authority).permit(
        :signatory_name,
        :signatory_job_title,
        :enquiries_paragraph,
        :email_address,
        :feedback_email,
        :press_notice_email,
        :reviewer_group_email,
        :notify_api_key,
        :letter_template_id,
        :email_reply_to_id
      )
    end
  end
end
