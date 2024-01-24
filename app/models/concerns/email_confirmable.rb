# frozen_string_literal: true

module EmailConfirmable
  extend ActiveSupport::Concern
  def send_confirmation_instructions
    token = set_reset_password_token
    send_reset_password_instructions_notification(token)
    token
  end

  def update_password(new_password, new_password_confirmation)
    self.password = new_password
    self.password_confirmation = new_password_confirmation
  end

  def reset_password(new_password, new_password_confirmation)
    if new_password.present? && confirmed?
      update_password(new_password, new_password_confirmation)
      save # rubocop:disable Rails/SaveBang
    elsif new_password.present?
      update_password(new_password, new_password_confirmation)
      confirm if save
    else
      errors.add(:password, :blank)
      false
    end
  end
end
