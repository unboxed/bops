# frozen_string_literal: true

class LocalAuthoritiesController < ApplicationController
  include Administratable

  before_action :set_local_authority, only: %i[edit update]

  def edit
  end

  def update
    if @local_authority.update(local_authority_params)
      flash[:notice] = I18n.t(
        "administrator_dashboard.show.local_authority_successfully_updated"
      )

      redirect_to administrator_dashboard_path
    else
      render :edit
    end
  end

  private

  def local_authority_params
    params.require(:local_authority).permit(:reviewer_group_email, :press_notice_email)
  end

  def set_local_authority
    @local_authority = current_local_authority
  end
end
