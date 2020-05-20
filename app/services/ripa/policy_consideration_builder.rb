# frozen_string_literal: true

class Ripa::PolicyConsiderationBuilder
  def initialize(consideration_json)
    @consideration_hash = JSON.parse(consideration_json)
  end

  def build_policy_considerations
    consideration_hash.fetch("flow", []).map do |consideration|
      policy_question = consideration["text"]

      chosen_option_id = consideration.dig("choice", "id")

      chosen_option = consideration.fetch("options", []).find(-> { {} }) { |o| o["id"] == chosen_option_id }

      applicant_answer_text = chosen_option["text"]

      if policy_question && applicant_answer_text
        PolicyConsideration.new(
          policy_question: policy_question,
          applicant_answer: applicant_answer_text
        )
      end
    end.compact
  end

  private

  attr_reader :consideration_hash
end
