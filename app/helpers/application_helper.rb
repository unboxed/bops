# frozen_string_literal: true

module ApplicationHelper
  def full_details(user)
    details = "#{user.name},<br/>
               #{user.phone},<br/>
               #{user.email}"
    details.html_safe
  end
end
