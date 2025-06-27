# frozen_string_literal: true

require "csv"

class ImportSiteHistoryJob < ApplicationJob
  def perform(local_authority_name:, create_class_name:)
    @local_authority_name = local_authority_name
    @create_class_name = create_class_name
    create_tempfile
    import_csv
  rescue => e
    log_exception(e)
  end

  private

  attr_reader :local_authority_name, :create_class_name

  def log_exception(exception)
    broadcast(message: exception.message)
    broadcast(message: "Expected S3 filepath: site_history/#{filename}") unless local_import_file_enabled?
  end

  def broadcast(message:)
    Rails.logger.info(message)
    Rails.logger.debug(message)
  end

  def import_csv
    import_rows
  end

  def create_class
    @create_class ||= create_class_name.to_s.constantize
  end

  def import_rows
    CSV.foreach(@file.path, headers: true, header_converters: :symbol) do |row|
      import_row(row)
    end

    @file.unlink
  end

  def create_tempfile
    @file = Tempfile.new(["site_history", ".csv"])
    write_tempfile(@file)
    @file.close
  end

  def write_tempfile(file)
    if local_import_file_enabled?
      Rails.logger.debug "local"
      file.write(local_import_file)
    else
      s3.get_object(bucket: "bops-#{Rails.env}-import", key: filename) do |chunk|
        file.write(chunk.dup.force_encoding("utf-8"))
      end
    end
  end

  def local_import_file
    Rails.root.join("tmp", filename).read
  end

  def filename
    "SiteHistory#{local_authority_name.capitalize}.csv"
  end

  def import_row(row)
    attributes = row.to_h

    if attributes[:previous_references].is_a?(String)
      attributes[:previous_references] = attributes[:previous_references].split(",").map(&:strip)
    end

    create_class.new(
      **attributes.merge(local_authority:)
    ).perform
  end

  def local_authority
    @local_authority ||= LocalAuthority.find_by!(short_name: local_authority_name)
  end

  def s3
    @s3 ||= Aws::S3::Client.new
  end

  def local_import_file_enabled?
    Rails.env.local?
  end
end
