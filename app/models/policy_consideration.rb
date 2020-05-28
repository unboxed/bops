# frozen_string_literal: true

class PolicyConsideration < ApplicationRecord
  ANSWER_PLACEHOLDER_CHAR = "_"

  validates :policy_question, presence: true
  validates :applicant_answer, presence: true

  belongs_to :policy_evaluation
end
