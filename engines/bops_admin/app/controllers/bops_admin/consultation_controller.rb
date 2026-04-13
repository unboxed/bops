# frozen_string_literal: true

module BopsAdmin
  class ConsultationController < SettingsController
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(local_authority_params, :consultation)
          format.html do
            redirect_to edit_consultation_path, notice: t(".success")
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
      %i[consultation_postal_address]
    end
  end
end
