# frozen_string_literal: true

module Administrator
  class LocalAuthoritiesController < ApplicationController
    before_action :set_local_authority, only: %i[edit update]

    def show
    end

    def edit
    end

    def update
      if @local_authority.update(local_authority_params)
        flash[:notice] = t(
          "administrator.dashboards.show.local_authority_successfully_updated"
        )

        redirect_to administrator_local_authority_path
      else
        render :edit
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
        :notify_letter_template,
        :reply_to_notify_id,
        :email_reply_to_id
      )
    end

    def set_local_authority
      @local_authority = current_local_authority
    end
  end
end
