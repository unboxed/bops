# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  enum role: { assessor: 0, reviewer: 1 }

  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable, request_keys: [:subdomains]

  has_many :decisions, dependent: :restrict_with_exception
  has_many :planning_applications, through: :decisions
  has_many :audits, dependent: :nullify
  belongs_to :local_authority, optional: false

  def self.find_for_authentication(tainted_conditions)
    if tainted_conditions[:subdomains].present?
      local_authority = LocalAuthority.find_by(subdomain: tainted_conditions[:subdomains].first)
      tainted_conditions.delete(:subdomains)
      find_first_by_auth_conditions(tainted_conditions.merge(local_authority_id: local_authority.id))
    else
      find_first_by_auth_conditions(tainted_conditions)
    end
  end
end
