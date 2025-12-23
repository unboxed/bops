# frozen_string_literal: true

module BopsApi
  module Application
    class DocumentsService
      def initialize(planning_application:, user:, files:)
        @planning_application = planning_application
        @user = user
        @files = files
      end

      def call!
        files.each do |file|
          url = file["name"]
          tags = file["type"].flat_map { |type| Array(type["value"]) }
          description = file["description"]

          upload(planning_application, user, url, tags, description)
        end
      end

      private

      attr_reader :planning_application, :user, :files

      def upload(planning_application, user, url, tags, description)
        if user.file_downloader.blank?
          raise Errors::FileDownloaderNotConfiguredError, "Please configure the file downloader for API user '#{user.id}'"
        end

        file = user.file_downloader.get(url: url, from_production: planning_application.from_production?)
        name = URI.decode_uri_component(File.basename(URI.parse(url).path))

        planning_application.documents.create! do |document|
          document.api_user = user
          document.submission = planning_application.case_record&.submission
          document.tags = tags
          document.applicant_description = description
          document.file.attach(io: file.open, filename: name)

          document_checklist = planning_application.document_checklist

          tags.each do |tag|
            next if tag.blank?
            next unless (item = document_checklist.document_checklist_items.find_by(tags: tag))

            document.document_checklist_items_id = item.id
          end
        end
      end
    end
  end
end
