# frozen_string_literal: true

require "base64"
require "zlib"

class ApiUser < ApplicationRecord
  include StoreModel::NestedAttributes

  TOKEN_FORMAT = /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/
  VALID_PERMISSIONS = %w[
    planning_application:read planning_application:write
    comment:read comment:write
    validation_request:read validation_request:write
  ].freeze

  attribute :file_downloader, FileDownloaders.to_type
  alias_attribute :value, :token

  belongs_to :local_authority
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :by_name, -> { reorder(:name) }

  validates :name, presence: true, uniqueness: {scope: :local_authority_id, conditions: -> { where(revoked_at: nil) }}
  validates :token, format: {with: TOKEN_FORMAT}, on: :create
  validates :file_downloader, store_model: true
  validates :permissions, presence: true, on: :create
  validates :permissions, inclusion: {in: VALID_PERMISSIONS}

  accepts_nested_attributes_for :file_downloader

  class << self
    def authenticate(token)
      active.find_by(token: token).tap { |user| user.try(:touch, :last_used_at) }
    end

    def generate_unique_secure_token(length: 36)
      super.then { |token| "bops_#{token}#{checksum(token)}" }
    end

    def valid_token?(token)
      TOKEN_FORMAT.match?(token) && checksum(token[5..40]) == token[41..46]
    end

    private

    def checksum(token)
      Base64.urlsafe_encode64([Zlib.crc32(token)].pack("L"), padding: false)
    end
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
end
