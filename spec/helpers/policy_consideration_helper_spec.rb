# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConsiderationHelper do
  before do
    stub_const("PolicyConsideration::ANSWER_PLACEHOLDER_CHAR", "_")
  end

  describe "#policy_question_fragments" do
    describe "splits on the first contiguous run of placeholder chars and strips whitespace" do
      it { expect(policy_question_fragments("This property is")).to eq(["This property is"]) }
      it { expect(policy_question_fragments("This property is _____")).to eq(["This property is", ""]) }
      it { expect(policy_question_fragments("This ____ a nice property ")).to eq(["This", "a nice property"]) }
      it { expect(policy_question_fragments("____ is a nice property ")).to eq(["", "is a nice property"]) }
      it { expect(policy_question_fragments("____ is a nice property ____ ")).to eq(["", "is a nice property ____"]) }
    end
  end
end
