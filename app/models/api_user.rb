# frozen_string_literal: true

require "base64"
require "openssl"
require "sqids"
require "zlib"

class ApiUser < ApplicationRecord
  include StoreModel::NestedAttributes

  TOKEN_FORMAT = /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/
  VALID_PERMISSIONS = %w[
    planning_application:read planning_application:write
    comment:read comment:write
    validation_request:read validation_request:write
  ].freeze

  alphabet = ENV.fetch("SQIDS_API_USER_ALPHABET", "nybqj43cv7zf9056d2sl8tpu1kwheroimxga")
  min_length = Integer(ENV.fetch("SQIDS_API_USER_MIN_LENGTH", "8"))
  SQIDS = Sqids.new(alphabet: alphabet, min_length: min_length)

  attribute :file_downloader, FileDownloaders.to_type
  alias_attribute :value, :token

  belongs_to :local_authority
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :by_name, -> { reorder(:name) }

  enum :authentication_type, %i[bearer hmac].index_with(&:to_s), suffix: "authentication", scopes: false

  validates :name, presence: true, uniqueness: {scope: :local_authority_id, conditions: -> { where(revoked_at: nil) }}
  validates :token, format: {with: TOKEN_FORMAT}, on: :create
  validates :product_id, :client_id, :client_secret, presence: true, if: :hmac_authentication?
  validates :file_downloader, store_model: true
  validates :permissions, presence: true, on: :create
  validates :permissions, inclusion: {in: VALID_PERMISSIONS}

  accepts_nested_attributes_for :file_downloader

  before_save if: :bearer_authentication? do
    assign_attributes(product_id: nil, client_id: nil, client_secret: nil)
  end

  class << self
    def authenticate(token)
      active.find_by(token: token).tap { |user| user.try(:touch, :last_used_at) }
    end

    def authenticate_with_hmac(sqid, signature, timestamp)
      active.find_by_sqid!(sqid).tap do |user|
        user.validate_hmac!(signature, timestamp)
        user.touch(:last_used_at)
      end
    rescue ActiveRecord::RecordNotFound, ArgumentError
      nil
    end

    def generate_unique_secure_token(length: 36)
      super.then { |token| "bops_#{token}#{checksum(token)}" }
    end

    def valid_token?(token)
      TOKEN_FORMAT.match?(token) && checksum(token[5..40]) == token[41..46]
    end

    def sqids
      SQIDS
    end

    def decode_sqid(sqid)
      sqids.decode(sqid).first
    end

    def encode_sqid(id)
      sqids.encode([id])
    end

    def find_by_sqid(sqid)
      find_by(id: decode_sqid(sqid))
    end

    def find_by_sqid!(sqid)
      find(decode_sqid(sqid))
    end

    private

    def checksum(token)
      Base64.urlsafe_encode64([Zlib.crc32(token)].pack("L"), padding: false)
    end
  end

  delegate :encode_sqid, to: :class

  def sqid
    encode_sqid(id)
  end

  def hmac_signature(timestamp)
    hmac_digest(hmac_data(timestamp))
  end

  def validate_hmac!(signature, timestamp)
    validate_hmac(signature, timestamp) ? true : raise_hmac_invalid_error
  end

  def revoke!
    touch(:revoked_at)
  end

  def revoked?
    revoked_at?
  end

  def active?
    !revoked?
  end

  def permits?(permission)
    permissions&.include?(permission)
  end

  private

  def hmac_data(timestamp)
    [product_id, client_id, timestamp].join("|")
  end

  def hmac_digest(data)
    OpenSSL::HMAC.base64digest("SHA256", client_secret, data)
  end

  def validate_hmac(signature, timestamp)
    secure_compare(hmac_digest(hmac_data(timestamp)), signature)
  end

  def raise_hmac_invalid_error
    raise ArgumentError, "HMAC signature is invalid"
  end

  def secure_compare(a, b)
    ActiveSupport::SecurityUtils.secure_compare(a, b)
  end
end
