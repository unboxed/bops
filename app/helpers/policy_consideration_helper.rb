# frozen_string_literal: true

module PolicyConsiderationHelper
  def policy_question_fragments(question)
    question.split(
      /#{PolicyConsideration::ANSWER_PLACEHOLDER_CHAR}+/, 2
    ).map(&:strip)
  end
end
