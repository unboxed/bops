# frozen_string_literal: true

require "rails_helper"

RSpec.describe "session expiry" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  def new_browser(current_local_authority: local_authority)
    open_session { |s| s.host! "#{current_local_authority.subdomain}.bops.localhost" }
  end

  context "when a new session is created" do
    it "logs out existing sessions" do
      s1 = new_browser
      s1.sign_in assessor
      s1.get "/"
      expect(s1.response.status).to eq 200

      s2 = new_browser
      s2.sign_in assessor
      s2.get "/"
      expect(s2.response.status).to eq 200

      s1.get "/"
      expect(s1.response.status).to eq 302
      expect(s1.response.headers["Location"]).to eq "http://#{local_authority.subdomain}.bops.localhost/users/sign_in"
    end
  end

  context "when a session is destroyed" do
    it "resets the persistence token" do
      s1 = new_browser
      s1.sign_in assessor
      original_token = assessor.persistence_token
      s1.get "/"
      expect(s1.response.status).to eq 200
      s1.sign_out assessor

      s1.get "/"
      expect(s1.response.status).to eq 302

      expect(assessor.persistence_token).not_to eq original_token
    end
  end

  context "when a session is used on another local authority" do
    let(:other_local_authority) { create(:local_authority, :default, subdomain: "other") }
    it "rejects the authentication" do
      s1 = new_browser
      s1.sign_in assessor
      s1.get "/planning_applications/"
      expect(s1.response.status).to eq 200

      s2 = new_browser(current_local_authority: other_local_authority)
      s2.cookies[:_bops_session] = s1.cookies[:_bops_session]
      s2.get "/"
      expect(s2.response.status).to eq 302
    end
  end

  context "when several sessions are created in quick succession" do
    before do
      ActionController::Base.cache_store = :solid_cache_store
    end

    it "rejects the signin attempt" do
      session = new_browser
      1.upto(30) do |i|
        session.post "/users/sign_in", params: {user: {email: "foo@example.com"}}
      end

      expect(session.response.status).to eq 429
    end

    after do
      ActionController::Base.cache_store = Rails.configuration.cache_store
    end
  end
end
