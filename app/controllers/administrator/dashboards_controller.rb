# frozen_string_literal: true

module Administrator
  class DashboardsController < ApplicationController
    def show
      @local_authority = current_local_authority
      @users = @local_authority.users
    end
  end
end
