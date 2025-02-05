# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  GLOBAL_SUBDOMAINS = %w[config].freeze

  attribute :subdomain
  attribute :user
  attribute :api_user
  attribute :local_authority

  def global_subdomain?
    GLOBAL_SUBDOMAINS.include?(subdomain)
  end

  def user_scope
    if global_subdomain?
      User.global.kept
    elsif local_authority
      local_authority.users.kept
    else
      User.none
    end
  end
end
