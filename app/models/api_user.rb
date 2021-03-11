# frozen_string_literal: true

class ApiUser < ApplicationRecord
  validates :name, :token, presence: true
  has_many :audits, dependent: :nullify
end
