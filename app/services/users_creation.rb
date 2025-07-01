# frozen_string_literal: true

class UsersCreation
  ATTRIBUTES = %i[
    name
    role
    email
    deactivated_at
    local_authority
  ].freeze

  def initialize(**params)
    ATTRIBUTES.each do |attribute|
      value = params[attribute]
      value = value.is_a?(String) ? value.strip : value
      instance_variable_set(:"@#{attribute}", value)
    end
  end

  def perform
    importer
  end

  private

  attr_reader(*ATTRIBUTES)

  def importer
    normalized_email = normalize_email(email)
    return nil if User.exists?(email: normalized_email)

    user = User.new(**user_attributes.merge(email: normalized_email))

    user.skip_confirmation_notification! if user.deactivated_at.present?

    user.save!
  rescue => e
    Rails.logger.debug { "[IMPORT ERROR] #{e.class}: #{e.message}" }
    Rails.logger.debug e.record&.errors&.full_messages&.join(", ")
    raise
  end

  def normalize_email(value)
    value.to_s.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, "").downcase
  end

  def user_attributes
    {
      name:,
      role:,
      deactivated_at:,
      local_authority:
    }
  end
end
