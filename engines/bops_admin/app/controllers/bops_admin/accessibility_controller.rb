# frozen_string_literal: true

module BopsAdmin
  class AccessibilityController < SettingsController
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(local_authority_params, :accessibility)
          format.html do
            redirect_to edit_accessibility_path, notice: t(".success")
          end
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
      %i[accessibility_postal_address accessibility_phone_number accessibility_email_address]
    end
  end
end
