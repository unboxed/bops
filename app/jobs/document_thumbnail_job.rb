# frozen_string_literal: true

class DocumentThumbnailJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    document.file.representation(resize_to_limit: [200, 200]).processed
  end
end
