# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  enum role: { assessor: 0, reviewer: 1, admin: 2 }

  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable, request_keys: [:subdomains]

  has_many :decisions, dependent: :restrict_with_exception
  has_many :planning_applications, through: :decisions
  belongs_to :local_authority

  def self.find_first_by_auth_conditions(conditions)
    local_authority = LocalAuthority.find_by(subdomain: conditions[:subdomains].first)
    find_by(email: conditions[:email], local_authority: local_authority.id)
  end
end
