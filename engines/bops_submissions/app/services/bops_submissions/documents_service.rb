# frozen_string_literal: true

module BopsSubmissions
  class DocumentsService
    def initialize(case_record:, user:, files:)
      @case_record = case_record
      @user = user
      @files = files
    end

    def call!
      files.each do |file|
        url = file["name"]
        tags = file["type"].flat_map { |type| Array(type["value"]) }
        description = file["description"]

        upload(case_record, user, url, tags, description)
      end
    end

    private

    attr_reader :case_record, :user, :files

    def upload(case_record, user, url, tags, description)
      if user.file_downloader.blank?
        raise Errors::FileDownloaderNotConfiguredError, "Please configure the file downloader for API user '#{user.id}'"
      end

      file = user.file_downloader.get(url: url)
      name = URI.decode_uri_component(File.basename(URI.parse(url).path))

      case_record.documents.create! do |document|
        document.tags = tags
        document.applicant_description = description
        document.file.attach(io: file.open, filename: name)
      end
    end
  end
end
