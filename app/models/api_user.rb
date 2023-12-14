# frozen_string_literal: true

class ApiUser < ApplicationRecord
  attribute :file_downloader, FileDownloaders.to_type

  belongs_to :local_authority, optional: true
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36

  with_options presence: true do
    validates :name, uniqueness: true
    validates :file_downloader, store_model: true
  end

  class << self
    def authenticate(token)
      find_by(token: token)
    end
  end
end
