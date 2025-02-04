# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching for policy references" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:policy_reference) { create(:local_authority_policy_reference, local_authority:, code: "P02", description: "New family homes") }

  subject { JSON.parse(response.body) }

  before do
    login_as(assessor)
  end

  before do
    get "/policy/references.json", params: {q: query}
  end

  context "when no policy reference matches the search query" do
    let(:query) { "Design" }

    it "returns an empty array" do
      expect(subject).to be_empty
    end
  end

  context "when a policy reference matches the search query on the code" do
    let(:query) { "P02" }

    it "returns the policy reference" do
      expect(subject).to match_array([
        a_hash_including("description" => "New family homes")
      ])
    end
  end

  context "when a policy reference matches the search query on the description" do
    let(:query) { "Family" }

    it "returns the policy reference" do
      expect(subject).to match_array([
        a_hash_including("description" => "New family homes")
      ])
    end
  end
end
