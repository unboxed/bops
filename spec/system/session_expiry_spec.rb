# frozen_string_literal: true

require "rails_helper"

RSpec.describe "session expiry" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  def new_browser
    open_session { |s| s.host! "#{local_authority.subdomain}.bops.localhost" }
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
end
