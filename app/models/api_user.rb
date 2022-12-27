# frozen_string_literal: true

class ApiUser < ApplicationRecord
  belongs_to :local_authority, optional: true

  validates :name, :token, presence: true
  has_many :audits, dependent: :nullify
end
