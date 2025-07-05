# frozen_string_literal: true

class MigrateImmunityDecisionReasons < ActiveRecord::Migration[7.2]
  class Review < ActiveRecord::Base
    store_accessor :specific_attributes, :decision_type
    store_accessor :specific_attributes, :decision_reason

    REASONS = YAML.load <<~EOF
      substantial-completion-on-or-after-2024-04-25: >-
        No action has been taken within 10 years of substantial completion for a
        breach of planning control consisting of operational development where
        substantial completion took place on or after 25 April 2024
      unauthorised-change-on-or-after-2024-04-25: >-
        No action has been taken within 10 years for an unauthorised
        change of use to a single dwellinghouse where the change of use
        took place on or after 25 April 2024
      substantial-completion-before-2024-04-25: >-
        No action has been taken within 4 years of substantial completion for a
        breach of planning control consisting of operational development where
        substantial completion took place before 25 April 2024
      unauthorised-change-before-2024-04-25: >-
        No action has been taken within 4 years for an unauthorised
        change of use to a single dwellinghouse where the change of use
        took place before 25 April 2024
      other-breach-of-planning-control: >-
        No action has been taken within 10 years for any other breach
        of planning control (essentially other changes of use)
    EOF

    TRANSFORMATIONS = YAML.load <<~EOF
      substantial-completion-on-or-after-2024-04-25: >-
        no action is taken within 10 years of substantial completion for
        a breach of planning control consisting of operational development
      substantial-completion-before-2024-04-25: >-
        no action is taken within 4 years of substantial completion for
        a breach of planning control consisting of operational development
      unauthorised-change-before-2024-04-25: >-
        no action is taken within 4 years for an unauthorised
        change of use to a single dwellinghouse
      other-breach-of-planning-control: >-
        no action is taken within 10 years for any other breach of planning control (essentially other changes of use)
    EOF

    class << self
      def enforcements
        where("specific_attributes->>'review_type' = 'enforcement'")
      end
    end

    def migrate!
      if TRANSFORMATIONS.value?(decision_type)
        self.decision_type = TRANSFORMATIONS.key(decision_type)
        self.decision_reason = REASONS.fetch(decision_type)
      end

      save!
    end

    def rollback!
      if TRANSFORMATIONS.key?(decision_type)
        self.decision_reason = TRANSFORMATIONS.fetch(decision_type)
        self.decision_type = decision_reason
      end

      save!
    end
  end

  def change
    reviews = Review.enforcements

    reversible do |dir|
      dir.up do
        reviews.find_each(&:migrate!)
      end

      dir.down do
        reviews.find_each(&:rollback!)
      end
    end
  end
end
