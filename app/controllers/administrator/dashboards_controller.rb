# frozen_string_literal: true

module Administrator
  class DashboardsController < ApplicationController
    include Administratable

    def show
      @local_authority = current_local_authority
      @users = @local_authority.users
    end
  end
end
