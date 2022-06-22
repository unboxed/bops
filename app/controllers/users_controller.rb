# frozen_string_literal: true

class UsersController < AuthenticationController
  before_action :set_user, only: %i[edit update]

  def new
    @user = current_local_authority.users.new
  end

  def create
    @user = current_local_authority.users.new(user_params)

    if @user.save
      flash[:alert] = I18n.t("users.index.successfully_created")
      redirect_to users_path
    else
      render :new
    end
  end

  def index
    @users = current_local_authority.users
  end

  def edit; end

  def update
    if @user.update(user_params)
      flash[:alert] = I18n.t("users.index.successfully_updated")
      redirect_to users_path
    else
      render :edit
    end
  end

  private

  def user_params
    params
      .require(:user)
      .permit(:name, :email, :password, :mobile_number, :role)
      .transform_values(&:presence)
  end

  def set_user
    @user = current_local_authority.users.find(params[:id])
  end

  def enforce_user_permissions
    redirect_to root_path unless current_user&.administrator?
  end
end
