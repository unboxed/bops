# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  included do
    def recommendation_submitted_and_unchallenged?
      planning_application.recommendation&.submitted_and_unchallenged?
    end
  end
end
