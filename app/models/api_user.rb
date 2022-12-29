# frozen_string_literal: true

class ApiUser < ApplicationRecord
  belongs_to :local_authority, optional: true

  validates :name, presence: true, uniqueness: true
  has_many :audits, dependent: :nullify

  has_secure_token :token, length: 36
end
