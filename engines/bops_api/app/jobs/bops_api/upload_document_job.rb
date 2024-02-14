# frozen_string_literal: true

module BopsApi
  class UploadDocumentJob < ApplicationJob
    queue_as :submissions
    discard_on ActiveJob::DeserializationError

    def perform(planning_application, user, url, tags, description)
      if user.file_downloader.blank?
        raise Errors::FileDownloaderNotConfiguredError, "Please configure the file downloader for API user '#{user.id}'"
      end

      file = user.file_downloader.get(url)
      name = URI.decode_uri_component(File.basename(URI.parse(url).path))

      planning_application.documents.create! do |document|
        document.tags = tags
        document.applicant_description = description
        document.file.attach(io: file.open, filename: name)

        tags.any? do |tag|
          document.document_checklist_items_id = planning_application.document_checklist.document_checklist_items.find_by(tags: tag).id
        end
      end
    end
  end
end
