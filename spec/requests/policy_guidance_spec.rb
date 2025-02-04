# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching for policy guidance" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:policy_guidance) { create(:local_authority_policy_guidance, local_authority:, description: "Heritage SPD") }

  subject { JSON.parse(response.body) }

  before do
    login_as(assessor)
  end

  before do
    get "/policy/guidance.json", params: {q: query}
  end

  context "when no policy guidance matches the search query" do
    let(:query) { "Design" }

    it "returns an empty array" do
      expect(subject).to be_empty
    end
  end

  context "when policy guidance matches the search query" do
    let(:query) { "Heritage" }

    it "returns the policy guidance" do
      expect(subject).to match_array([
        a_hash_including("description" => "Heritage SPD")
      ])
    end
  end
end
