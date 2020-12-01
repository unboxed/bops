# frozen_string_literal: true

class Ripa::PolicyConsiderationBuilder
  def initialize(consideration_json)
    @consideration_hash = JSON.parse(consideration_json)
  end

  def import
    if consideration_hash
      consideration_hash.fetch("flow", []).map do |consideration|
        parse_and_build_policy_consideration(consideration)
      end.compact
    end
  end

  private

  attr_reader :consideration_hash

  def parse_and_build_policy_consideration(consideration)
    policy_question = consideration["text"]

    chosen_option_id = consideration.dig("choice", "id")

    chosen_option = consideration.fetch("options", []).find(-> { {} }) do |o|
      o["id"] == chosen_option_id
    end

    applicant_answer_text = chosen_option["text"]

    build_policy_consideration(policy_question, applicant_answer_text)
  end

  def build_policy_consideration(policy_question, applicant_answer)
    if policy_question && applicant_answer
      PolicyConsideration.new(
        policy_question: policy_question,
        applicant_answer: applicant_answer
      )
    end
  end
end
