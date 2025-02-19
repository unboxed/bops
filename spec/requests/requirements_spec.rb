# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching for requirements" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:requirement) { create(:local_authority_requirement, local_authority:, category: "other", description: "Floor plans – existing") }

  subject { JSON.parse(response.body) }

  before do
    sign_in(assessor)
  end

  before do
    get "/requirements.json", params: {q: query}
  end

  context "when no requirements matches the search query" do
    let(:query) { "Photographs" }

    it "returns an empty array" do
      expect(subject).to be_empty
    end
  end

  context "when a requirement matches the search query" do
    let(:query) { "Floor plans" }

    it "returns the requirement" do
      expect(subject).to match_array([
        a_hash_including(
          "category" => "Other requirements",
          "description" => "Floor plans – existing"
        )
      ])
    end
  end
end
