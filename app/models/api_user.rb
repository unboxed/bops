# frozen_string_literal: true

class ApiUser < ApplicationRecord
  attribute :file_downloader, FileDownloaders.to_type

  belongs_to :local_authority, optional: true
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36

  validates :name, presence: true, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :file_downloader, store_model: {allow_blank: true}

  class << self
    def authenticate(token)
      find_by(token: token)
    end
  end
end
