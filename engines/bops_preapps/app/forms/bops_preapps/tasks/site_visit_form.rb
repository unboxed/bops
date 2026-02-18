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

      self.task_actions = %w[add_site_visit save_draft save_and_complete update_site_visit remove_site_visit]

      attribute :visited_on, :date
      attribute :address, :string
      attribute :comments, :string
      attribute :documents, array: true
      attribute :site_visit_id, :integer
      attribute :documents_to_remove, :list

      with_options on: :add_site_visit do
        validates :visited_on, date: {format: true, message: "Enter a valid date for the site visit"}
        validates :visited_on, date: {presence: true, message: "Enter the date of the site visit"}
        validates :visited_on, date: {on_or_before: :current, message: "Enter a date on or before today’s date"}
        validates :address, presence: {message: "Enter the address of the site"}
        validates :comments, presence: {message: "Enter some comments about the site visit"}
        validate :documents_have_permitted_file_types
      end

      with_options on: :update_site_visit do
        validates :visited_on, date: {format: true, message: "Enter a valid date for the site visit"}
        validates :visited_on, date: {presence: true, message: "Enter the date of the site visit"}
        validates :visited_on, date: {on_or_before: :current, message: "Enter a date on or before today’s date"}
        validates :address, presence: {message: "Enter the address of the site"}
        validates :comments, presence: {message: "Enter some comments about the site visit"}
        validate :documents_have_permitted_file_types
      end

      after_initialize do
        self.address = planning_application.address.presence
        if params[:site_visit_id].present?
          self.visited_on ||= site_visit.visited_at&.to_date
        end
      end

      def site_visits
        @site_visits ||= site_visits_relation.load
      end

      def site_visit
        @site_visit ||= planning_application.site_visits.find(site_visit_id.presence || params[:site_visit_id])
      end

      def each_site_visit
        site_visits.each do |site_visit|
          yield SiteVisitDecorator.new(site_visit)
        end
      end

      def add_site_visit_open?
        errors.any? || site_visits.none?
      end

      def edit_url
        route_for(:edit_task, planning_application, task, site_visit_id: planning_application.site_visits.find(site_visit_id), only_path: true)
      end

      def flash(type, controller)
        case action
        when "add_site_visit", "remove_site_visit", "update_site_visit"
          case type
          when :notice
            controller.t(".#{slug}.#{action}.success")
          when :alert
            controller.t(".#{slug}.#{action}.failure")
          end
        else
          super
        end
      end

      private

      def site_visits_relation
        planning_application.site_visits.includes(:created_by, documents: {file_attachment: :blob}).by_visited_at_desc
      end

      def form_params(params)
        params.require(param_key).permit(:visited_on, :address, :comments, :site_visit_id, :document_id, documents_to_remove: [], documents: [])
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

      def remove_site_visit
        transaction do
          planning_application.site_visits.find(site_visit_id).delete
        end
      end

      def update_site_visit
        remove_documents(documents_to_remove)

        transaction do
          planning_application.site_visits
            .find(site_visit_id)
            .update!(
              visited_at: visited_on,
              address: address,
              comment: comments,
              documents: documents
            ) && task.start!
        end
      end

      def remove_documents(documents_to_remove)
        return if documents_to_remove.blank?

        transaction do
          site_visit = planning_application.site_visits.find(site_visit_id)
          site_visit.documents.where(id: documents_to_remove.compact_blank).find_each(&:destroy!)
        end
      end

      def documents_have_permitted_file_types
        return unless documents.compact_blank.any? do |document|
          Document::PERMITTED_CONTENT_TYPES.exclude?(document.content_type)
        end

        errors.add(:documents, "The file type must be JPEG, PNG or PDF") if invalid
      end
    end
  end
end
