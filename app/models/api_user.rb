# frozen_string_literal: true

class ApiUser < ApplicationRecord
  attribute :file_downloader, FileDownloaders.to_type

  belongs_to :local_authority
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  validates :name, presence: true, uniqueness: {scope: :local_authority_id}
  validates :file_downloader, store_model: {allow_blank: true}

  class << self
    def authenticate(token)
      active.find_by(token: token)
    end
  end
end
