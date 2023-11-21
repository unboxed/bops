# frozen_string_literal: true

class UsersController < AuthenticationController
  include Administratable

  before_action :set_user, only: %i[edit update]

  def new
    @user = current_local_authority.users.new
  end

  def edit
  end

  def create
    @user = current_local_authority.users.new(user_params)

    if @user.save

      @user.send_confirmation_instructions
      flash[:notice] = I18n.t(
        "administrator_dashboard.show.user_successfully_created"
      )

      redirect_to administrator_dashboard_path
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = I18n.t(
        "administrator_dashboard.show.user_successfully_updated"
      )

      redirect_to administrator_dashboard_path
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(permitted_params).transform_values(&:presence)
  end

  def permitted_params
    %i[name email otp_delivery_method password password_confirmation mobile_number role]
  end

  def set_user
    @user = current_local_authority.users.find(params[:id])
  end
end
