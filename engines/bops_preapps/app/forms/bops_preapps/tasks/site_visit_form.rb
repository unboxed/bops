# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteVisitForm < Form
      include DateValidateable

      class SiteVisitDecorator < SimpleDelegator
        def visited_on
          visited_at&.to_date&.to_fs
        end

        def created_by
          super&.name
        end
      end

      self.task_actions = %w[add_site_visit save_draft save_and_complete]

      attribute :visited_on, :date
      attribute :address, :string
      attribute :comments, :string
      attribute :documents, array: true

      with_options on: :add_site_visit do
        validates :visited_on, date: {format: true, message: "Enter a valid date for the site visit"}
        validates :visited_on, date: {presence: true, message: "Enter the date of the site visit"}
        validates :visited_on, date: {on_or_before: :current, message: "Enter a date on or before today’s date"}
        validates :address, presence: {message: "Enter the address of the site"}
        validates :comments, presence: {message: "Enter some comments about the site visit"}
      end

      after_initialize do
        self.address = planning_application.address.presence
      end

      def update(params)
        super do
          case action
          when "add_site_visit"
            add_site_visit
          when "save_draft"
            task.start!
          when "save_and_complete"
            task.complete!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def site_visits
        @site_visits ||= site_visits_relation.load
      end

      def each_site_visit
        site_visits.each do |site_visit|
          yield SiteVisitDecorator.new(site_visit)
        end
      end

      def add_site_visit_open?
        errors.any? || site_visits.none?
      end

      private

      def site_visits_relation
        planning_application.site_visits.includes(:created_by, documents: {file_attachment: :blob}).by_visited_at_desc
      end

      def form_params(params)
        params.require(param_key).permit(:visited_on, :address, :comments, documents: [])
      end

      def create_site_visit!
        planning_application.site_visits.create! do |sv|
          sv.visited_at = visited_on
          sv.address = address
          sv.comment = comments
          sv.decision = true
          sv.documents = documents
          sv.created_by = Current.user
        end
      end

      def add_site_visit
        transaction do
          create_site_visit! && task.start!
        end
      end
    end
  end
end
