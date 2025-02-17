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
        if current_local_authority.update(local_authority_params)
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
        :telephone_number,
        :feedback_email,
        :press_notice_email,
        :reviewer_group_email,
        :notify_api_key,
        :letter_template_id,
        :email_reply_to_id,
        :document_checklist,
        :planning_policy_and_guidance,
        :public_register_base_url
      )
    end
  end
end
