# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /index" do
    it "should redirect to login page" do
      get "/home/index"
      expect(response).to redirect_to("/users/sign_in")
    end
  end
end
