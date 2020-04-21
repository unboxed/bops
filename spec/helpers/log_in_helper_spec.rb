# frozen_string_literal: true

require 'rails_helper'

module Helpers
  module Login
    def sign_in(user)
      visit "/"
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      find_button('Log in').click
    end
  end
end
