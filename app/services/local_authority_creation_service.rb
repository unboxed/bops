# frozen_string_literal: true

class LocalAuthorityCreationService
  def initialize(params)
    @subdomain = params[:subdomain]
    @council_code = params[:council_code]
    @short_name = params[:short_name]
    @council_name = params[:council_name]
    @admin_email = params[:admin_email]

    @applicants_url = if Bops.env.production?
      params[:applicants_url]
    else
      "https://#{@subdomain}.#{Rails.configuration.applicants_base_url}"
    end
  end

  def call
    setup

    local_authority
  end

  private

  attr_reader :subdomain, :council_code, :short_name, :council_name, :applicants_url,
    :admin_email

  def setup
    local_authority
    create_administrator_user if admin_email
  end

  def local_authority
    @local_authority ||= LocalAuthority.find_or_create_by!(
      subdomain:,
      council_code:,
      short_name:,
      council_name:,
      applicants_url:,
      application_type_overrides:
    )
  end

  def application_type_overrides
    [{"code" => "preApp", "determination_period_days" => 30}]
  end

  def create_administrator_user
    User.find_or_create_by!(email: admin_email) do |user|
      user.local_authority = local_authority
      user.password = user.password_confirmation = PasswordGenerator.call
      user.role = :administrator
      user.otp_required_for_login = false
    end
  end
end
