# frozen_string_literal: true

class User < ApplicationRecord
  include BopsCore::AuditableModel
  include Discard::Model

  GLOBAL_ROLES = %w[global_administrator].freeze

  self.audit_attributes = %w[id name role]
  self.discard_column = :deactivated_at

  enum :role, {assessor: 0, reviewer: 1, administrator: 2, global_administrator: 3}
  enum :otp_delivery_method, {sms: 0, email: 1}

  devise :recoverable, :two_factor_authenticatable,
    :recoverable, :timeoutable, :validatable, :confirmable,
    otp_secret_encryption_key: Rails.configuration.otp_secret_encryption_key

  include EmailConfirmable

  has_many :planning_applications, -> { kept }, dependent: :nullify
  has_many :audits, dependent: :nullify
  has_many :comments, dependent: :nullify
  belongs_to :local_authority, optional: true

  before_create :generate_otp_secret

  before_validation on: :create do
    self.password = self.password_confirmation = PasswordGenerator.call
  end

  validates :mobile_number, phone_number: true
  validates :password, password_strength: {use_dictionary: true}, unless: ->(user) { user.password.blank? }
  validate :password_complexity
  validates :role, inclusion: {in: :local_roles}, if: -> { local_authority.present? }

  scope :non_administrator, -> { where.not(role: "administrator") }
  scope :global, -> { where(local_authority_id: nil) }
  scope :global_administrator, -> { global.where(role: "global_administrator") }
  scope :confirmed, -> { kept.where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { kept.where(confirmed_at: nil) }

  delegate :local_roles, :global_roles, to: :class

  class << self
    def menu(scope = User.all)
      users = scope.order(name: :asc).pluck(:name, :id)

      [["Unassigned", nil]].concat(users)
    end

    def by_name
      order(name: :asc)
    end

    def local_roles
      roles.keys - global_roles
    end

    def global_roles
      GLOBAL_ROLES
    end

    def find_for_authentication(tainted_conditions)
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

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    confirmed_at.nil?
  end

  def confirmation_timeout
    6.hours
  end

  def reset_persistence_token
    self.persistence_token = SecureRandom.hex(64)
  end

  def reset_persistence_token!
    SecureRandom.hex(64).tap { |token| update_column(:persistence_token, token) }
  end

  def valid_persistence_token?(token)
    persistence_token == token
  end

  private

  def generate_otp_secret
    self.otp_secret = self.class.generate_otp_secret
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    errors.add :password, "complexity requirement not met. Your password must have: " \
                          "at least 8 characters; at least one symbol (for example, ?!£%); at least one capital letter."
  end
end
