# frozen_string_literal: true

module BopsAdmin
  class SiteNoticesController < SettingsController
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(site_notice_params, :site_notices)
          format.html do
            redirect_to edit_site_notices_path, notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def site_notice_params
      params.require(:local_authority).permit(*local_authority_attributes)
    end

    def local_authority_attributes
      %i[site_notice_logo site_notice_phone_number site_notice_email_address site_notice_show_assigned_officer]
    end
  end
end
