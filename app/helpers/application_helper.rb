# frozen_string_literal: true

module ApplicationHelper
  def full_details(user)
    "#{user.name}, #{user.phone}, #{user.email}"
  end
end
