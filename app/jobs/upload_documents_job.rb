# frozen_string_literal: true

class UploadDocumentsJob < ApplicationJob
  queue_as :urgent

  def perform(planning_application:, files:)
    @file_attributes = files
    @planning_application = planning_application
    upload_files
  end

  private

  attr_reader :file_attributes, :planning_application

  def upload_files
    file_attributes&.each do |attributes|
      DocumentCreator.new(
        planning_application: planning_application,
        file_attributes: attributes
      ).create_document!
    end
  end
end
