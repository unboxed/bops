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

          UploadDocumentJob.set(wait: 5.minutes).perform_later(planning_application, user, url, tags, description)
        end
      end

      private

      attr_reader :planning_application, :user, :files
    end
  end
end
