# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searching for contacts" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  subject { JSON.parse(response.body) }

  before do
    sign_in(assessor)
  end

  describe "searching for consultees" do
    let!(:consultee) { create(:contact, name: "Mr White") }

    before do
      get "/contacts/consultees.json", params: {q: query}
    end

    context "when no consultees match the search query" do
      let(:query) { "Mr Black" }

      it "returns an empty array" do
        expect(subject).to be_empty
      end
    end

    context "when a consultee matches the search query" do
      let(:query) { "Mr White" }

      it "returns the consultee" do
        expect(subject).to match_array([
          a_hash_including("name" => "Mr White")
        ])
      end
    end
  end
end
