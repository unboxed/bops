# frozen_string_literal: true

class User < ApplicationRecord
  enum role: { assessor: 0, reviewer: 1, administrator: 2 }

  enum otp_delivery_method: { sms: 0, email: 1 }

  devise :recoverable, :two_factor_authenticatable, :recoverable, :timeoutable,
         :validatable, otp_secret_encryption_key: ENV["OTP_SECRET_ENCRYPTION_KEY"], request_keys: [:subdomains]

  has_many :planning_applications, dependent: :nullify
  has_many :audits, dependent: :nullify
  has_many :comments, dependent: :nullify
  belongs_to :local_authority, optional: false

  before_create :generate_otp_secret

  validates :mobile_number, phone_number: true
  validates :password, password_strength: { use_dictionary: true }, unless: ->(user) { user.password.blank? }
  validate :password_complexity

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

  def send_otp(session_mobile_number)
    if send_otp_by_sms?
      number = mobile_number.presence || session_mobile_number
      TwoFactor::SmsNotification.new(number, current_otp).deliver!
    else
      UserMailer.otp_mail(self).deliver_now
    end
  end

  def send_otp_by_sms?
    otp_delivery_method == "sms"
  end

  private

  def generate_otp_secret
    self.otp_secret = self.class.generate_otp_secret
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    errors.add :password, "complexity requirement not met. Your password must have: " \
                          "at least 8 characters; at least one symbol (e.g., ?!£%); at least one capital letter."
  end
end
