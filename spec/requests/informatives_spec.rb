# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching for informatives" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:informative) { create(:local_authority_informative, local_authority:, title: "Section 106") }

  subject { JSON.parse(response.body) }

  before do
    login_as(assessor)
  end

  before do
    get "/informatives.json", params: {q: query}
  end

  context "when no informatives match the search query" do
    let(:query) { "Biodiversity" }

    it "returns an empty array" do
      expect(subject).to be_empty
    end
  end

  context "when an informative matches the search query" do
    let(:query) { "Section 106" }

    it "returns the informative" do
      expect(subject).to match_array([
        a_hash_including("title" => "Section 106")
      ])
    end
  end
end
