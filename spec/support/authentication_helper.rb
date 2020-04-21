# frozen_string_literal: true

module AuthenticationHelper
  def sign_in(user)
    visit "/"
    fill_in("user[email]", with: user.email)
    fill_in("user[password]", with: user.password)

    click_button('Log in') # this is the same as this find_button('Log in').click
  end
end
