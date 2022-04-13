# frozen_string_literal: true

class User < ApplicationRecord
  enum role: { assessor: 0, reviewer: 1 }

  devise :recoverable, :two_factor_authenticatable, :recoverable, :timeoutable,
         :validatable, otp_secret_encryption_key: ENV["OTP_SECRET_ENCRYPTION_KEY"], request_keys: [:subdomains]

  has_many :decisions, dependent: :restrict_with_exception
  has_many :planning_applications, through: :decisions
  has_many :audits, dependent: :nullify
  belongs_to :local_authority, optional: false

  before_create :generate_otp_secret

  def self.find_for_authentication(tainted_conditions)
    if tainted_conditions[:subdomains].present?
      local_authority = LocalAuthority.find_by(subdomain: tainted_conditions[:subdomains].first)
      tainted_conditions.delete(:subdomains)
      find_first_by_auth_conditions(tainted_conditions.merge(local_authority_id: local_authority.id))
    else
      find_first_by_auth_conditions(tainted_conditions)
    end
  end

  def assign_mobile_number!(number)
    update!(mobile_number: number)
  end

  def valid_otp_attempt?(otp_attempt)
    validate_and_consume_otp!(otp_attempt)
  end

  private

  def generate_otp_secret
    self.otp_required_for_login = true
    self.otp_secret = self.class.generate_otp_secret
  end
end
