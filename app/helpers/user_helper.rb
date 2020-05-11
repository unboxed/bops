# frozen_string_literal: true

module UserHelper
  def full_details(user)
    "#{user.first_name} #{user.last_name}, #{user.phone}, #{user.email}"
  end
end
