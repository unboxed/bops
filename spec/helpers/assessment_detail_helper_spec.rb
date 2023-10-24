# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetailHelper do
  describe ".neighbour_responses_summary_text" do
    it "generates the correct text from a given hash" do
      summary_hash = {"objection" => 1, "supportive" => 2, "neutral" => 1}

      result = neighbour_responses_summary_text(summary_hash)
      expect(result).to eq("There is 1 objection, 2 supportive, 1 neutral.")
    end
  end
end
