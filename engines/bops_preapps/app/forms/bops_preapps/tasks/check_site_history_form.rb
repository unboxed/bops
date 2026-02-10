# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckSiteHistoryForm < Form
      include DateValidateable

      self.task_actions = %w[add_site_history save_and_complete save_draft]

      attribute :decision, :string
      attribute :comment, :string
      attribute :description, :string
      attribute :other_decision, :string
      attribute :reference, :string
      attribute :address, :string
      attribute :date, :date

      with_options on: :add_site_history do
        validates :reference, presence: {message: "Enter the application number"}
        validates :decision, presence: {message: "Choose a decision for the site history"}
        validates :description, presence: {message: "Enter the a description of the site history"}
        validates :date, presence: {message: "Enter the date of the site history"}, date: {on_or_before: :current}
      end

      def update(params)
        super do
          if action.in?(task_actions)
            send(action.to_sym)
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(site_history_checked: true)
          super
        end
      end

      def create_site_history!
        planning_application.site_histories.create! do |site_history|
          site_history.decision = (decision == "other") ? other_decision : decision
          site_history.comment = comment
          site_history.description = description
          site_history.application_number = reference
          site_history.address = address
          site_history.date = date
        end
      end

      def add_site_history
        transaction do
          create_site_history! && task.start!
        end
      end
    end
  end
end
