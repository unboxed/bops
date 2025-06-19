# frozen_string_literal: true

require "csv"

class ImportHistoricApplicationsJob < ApplicationJob

  def perform(local_authority_name:)
    @local_authority_name = local_authority_name
    create_tempfile
    import_planning_applications
  rescue StandardError => e
    log_exception(e)
  end

  private

  attr_reader :local_authority_name

  def log_exception(exception)
    broadcast(message: exception.message)
    broadcast(message: "Expected S3 filepath: historic_applications/#{filename}") unless ENV["LOCAL_IMPORT_FILE"] == "true"
  end

  def broadcast(message:)
    Rails.logger.info(message)
    Rails.logger.debug(message)
  end

  def import_planning_applications
    import_rows
  end

  def validate_planning_applications
    PlanningApplicationsValidation.new
  end

  def import_rows
    CSV.foreach(@file.path, headers: true, header_converters: :symbol) do |row|
      import_row(row)
    end

    @file.unlink
  end

  def create_tempfile
    @file = Tempfile.new(["planning_applications", ".csv"])
    write_tempfile(@file)
    @file.close
  end

  def write_tempfile(file)
    if ENV["LOCAL_IMPORT_FILE"] == "true"
      puts "local"
      file.write(local_import_file)
    else
      s3.get_object(bucket: "bops-#{ENV['BOPS_ENVIRONMENT']}-import", key: filename) do |chunk|
        file.write(chunk.dup.force_encoding("utf-8"))
      end
    end
  end

  def local_import_file
    Rails.root.join("tmp", filename).read
  end

  def filename
    "PlanningHistory#{local_authority_name.capitalize}.csv"
  end

  def import_row(row)
    PlanningApplicationsCreation.new(
      **row.to_h.merge(local_authority:)
    ).perform
  end

  def local_authority
    @local_authority ||= LocalAuthority.find_by!(short_name: local_authority_name)
  end

  # Uncomment this if you want to use S3 instead of the local import file
  # def s3
  #   @s3 ||= Aws::S3::Client.new
  # end
end
