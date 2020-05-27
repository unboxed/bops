# frozen_string_literal: true

require "rails_helper"

RSpec.describe "policy_evaluations/_question_answer_pair.html.erb" do
  context "with a sequential question and answer" do
    let(:policy_consideration) do
      build :policy_consideration,
            policy_question: "What is your favourite ice cream?",
            applicant_answer: "Cornetto"
    end

    it "displays a sequential pair" do
      render "policy_evaluations/question_answer_pair", policy_consideration: policy_consideration

      expect(rendered).to include "What is your favourite ice cream? <strong>Cornetto</strong>"
    end
  end

  context "with a question with a placeholder for the answer" do
    let(:policy_consideration) do
      build :policy_consideration,
            policy_question: "Your dessert _____ melt in the sun",
            applicant_answer: "does"
    end

    it "displays a question with an interpolated answer" do
      render "policy_evaluations/question_answer_pair", policy_consideration: policy_consideration

      expect(rendered).to include "Your dessert <strong>does</strong> melt in the sun"
    end
  end
end
