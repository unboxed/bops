# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class AddInterestedPartiesForm < Form
      self.task_actions = %w[save_and_complete add_party remove_party]

      attribute :name, :string
      attribute :company_name, :string
      attribute :address_1, :string
      attribute :address_2, :string
      attribute :town, :string
      attribute :county, :string
      attribute :postcode, :string
      attribute :email_address, :string
      attribute :phone, :string
      attribute :relationship, :string
      attribute :other_relationship, :string

      with_options on: :add_party do
        validates :name, :address_1, :town, :postcode, :relationship, presence: true
        validates :other_relationship, presence: true, if: -> { relationship == "other" }
      end

      after_initialize do |params|
        person_id = @params.dig("tasks_add_interested_parties_form", "interested_party_id") || @params[:id]

        @person = enforcement.interested_parties.find_or_initialize_by(id: person_id) do |person|
          person.assign_attributes attributes
        end

        attributes.each_key do |k|
          send("#{k}=", person.send(k))
        end
      end
      attr_reader :person

      private

      def add_party
        person.update!(attributes)
      end

      def remove_party
        person.delete
      end
    end
  end
end
