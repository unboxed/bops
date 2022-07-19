# frozen_string_literal: true

class AdministratorDashboardController < ApplicationController
  include Administratable

  def show
    @local_authority = current_local_authority
    @users = @local_authority.users
  end
end
