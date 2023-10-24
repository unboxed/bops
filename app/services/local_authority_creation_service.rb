# frozen_string_literal: true

class LocalAuthorityCreationService
  def initialize(params)
    @subdomain = params.fetch(:subdomain, nil)
    @council_code = params.fetch(:council_code, nil)
    @short_name = params.fetch(:short_name, nil)
    @council_name = params.fetch(:council_name, nil)
    @applicants_url = params.fetch(:applicants_url, nil)
    @signatory_name = params.fetch(:signatory_name, nil)
    @signatory_job_title = params.fetch(:signatory_job_title, nil)
    @enquiries_paragraph = params.fetch(:enquiries_paragraph, nil)
    @email_address = params.fetch(:email_address, nil)
    @feedback_email = params.fetch(:feedback_email, nil)
    @admin_email = params.fetch(:admin_email, nil)
  end

  def call
    setup
  end

  private

  attr_reader :subdomain, :council_code, :short_name, :council_name, :applicants_url,
    :signatory_name, :signatory_job_title, :enquiries_paragraph,
    :email_address, :feedback_email, :admin_email

  def setup
    local_authority
    api_user
    create_administrator_user if admin_email
  end

  def local_authority
    @local_authority ||= LocalAuthority.find_or_create_by!(
      subdomain:,
      council_code:,
      short_name:,
      council_name:,
      applicants_url:,
      signatory_name:,
      signatory_job_title:,
      enquiries_paragraph:,
      email_address:,
      feedback_email:
    )
  end

  def api_user
    @api_user ||= ApiUser.find_or_create_by!(name: subdomain, local_authority:)
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
