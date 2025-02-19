# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to show document tags" do
  before do
    create(:local_authority, :default)
  end

  describe "#tags" do
    it "returns an object with an array of all the document tags, plan tags and evidence tags" do
      get "/api/v1/documents/tags"

      expect(response).to be_successful

      expect(json).to eq({
        "tags" => Document::TAGS,
        "evidence_tags" => Document::EVIDENCE_TAGS,
        "drawing_tags" => Document::DRAWING_TAGS
      })
    end
  end
end
