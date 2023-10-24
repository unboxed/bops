# frozen_string_literal: true

class UploadDocumentsService
  def initialize(files:, planning_application:)
    @files = files
    @planning_application = planning_application
  end

  def call
    files&.each do |file_params|
      filename = file_params[:filename]

      file = fetch_file(filename)

      raise Api::V1::Errors::WrongFileTypeError.new(nil, filename) if forbidden?(file.content_type)

      attach_files(planning_application, file, file_params)
    rescue OpenURI::HTTPError
      raise Api::V1::Errors::GetFileError.new(nil, filename)
    end
  end

  private

  attr_reader :files, :planning_application

  def new_filename(name)
    name.split("/")[-1]
  end

  def forbidden?(content_type)
    Document::PERMITTED_CONTENT_TYPES.exclude? content_type
  end

  def attach_files(planning_application, file, file_params)
    planning_application.documents.create!(tags: Array(file_params[:tags]),
      applicant_description: file_params[:applicant_description]) do |document|
      document.file.attach(io: file, filename: new_filename(file_params[:filename]).to_s)
    end
  end

  def fetch_file(filename)
    URI.parse(filename).open("api-key" => planx_file_api_key)
  end

  def planx_file_api_key
    if @planning_application.from_production?
      ENV.fetch("PLANX_FILE_PRODUCTION_API_KEY",
        nil)
    else
      ENV.fetch("PLANX_FILE_API_KEY", nil)
    end
  end
end
