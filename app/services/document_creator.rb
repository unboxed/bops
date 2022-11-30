# frozen_string_literal: true

class DocumentCreator
  def initialize(planning_application:, file_attributes:)
    @planning_application = planning_application
    @file_attributes = file_attributes
  end

  def create_document!
    validate_content_type
    document.file.attach(io: file, filename: new_filename)
    document.save!
  end

  private

  attr_reader :planning_application, :file_attributes

  def document
    @document ||= planning_application.documents.build(
      tags: file_attributes[:tags],
      applicant_description: file_attributes[:applicant_description]
    )
  end

  def file
    @file ||= URI.parse(filename).open("api-key" => ENV["PLANX_FILE_API_KEY"])
  rescue OpenURI::HTTPError
    raise Api::V1::Errors::GetFileError.new(nil, filename)
  end

  def new_filename
    filename.split("/").last
  end

  def filename
    @filename ||= file_attributes[:filename]
  end

  def validate_content_type
    return if Document::PERMITTED_CONTENT_TYPES.include?(file.content_type)

    raise Api::V1::Errors::WrongFileTypeError.new(nil, filename)
  end
end
