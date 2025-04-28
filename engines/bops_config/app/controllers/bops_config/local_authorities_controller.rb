# frozen_string_literal: true

module BopsConfig
  class LocalAuthoritiesController < ApplicationController
    before_action :set_local_authorities, only: %i[index]
    before_action :set_local_authority, only: %i[show edit update]
    before_action :build_local_authority, only: %i[new create]
    before_action :build_administrator, only: %i[new create]

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      @local_authority.attributes = local_authority_params
      @administrator.attributes = administrator_params

      respond_to do |format|
        if @local_authority.save
          format.html { redirect_to local_authorities_url, notice: t(".created") }
        else
          format.html { render :new }
        end
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @local_authority.update(local_authority_params)
          format.html { redirect_to local_authorities_url, notice: t(".updated") }
        else
          format.html { render :new }
        end
      end
    end

    private

    def set_local_authorities
      @local_authorities = LocalAuthority.by_short_name
    end

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: params[:name])
    end

    def build_local_authority
      api_user = ApiUser.find_by!(name: "bops-applicants")

      @local_authority = LocalAuthority.new do |la|
        la.api_users.new(name: "bops-applicants", token: api_user.token)
      end
    end

    def build_administrator
      @administrator = @local_authority.users.new(role: "administrator")

      PasswordGenerator.call.tap do |password|
        @administrator.password = password
        @administrator.password_confirmation = password
      end
    end

    def local_authority_params
      params.require(:local_authority).permit(*local_authority_attributes)
    end

    def local_authority_attributes
      %i[short_name council_name council_code subdomain applicants_url]
    end

    def administrator_params
      params.require(:administrator).permit(:name, :email)
    end
  end
end
