# frozen_string_literal: true

module UserHelper
  def full_details(user)
    "#{user.first_name} #{user.last_name}, #{user.phone}, #{user.email}"
  end

  def full_name(user)
    "#{user.first_name} #{user.last_name}"
  end
end
