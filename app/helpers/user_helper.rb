# frozen_string_literal: true

module UserHelper
  def full_details(user)
    "#{user.name}, #{user.phone}, #{user.email}"
  end
end
