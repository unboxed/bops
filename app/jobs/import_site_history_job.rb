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
    broadcast(message: "Expected S3 filepath: #{s3_key}") unless local_import_file_enabled?
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
      import_row(row.to_h)
    end

    @file.unlink
  end

  def import_row(attributes)
    if attributes[:previous_references].is_a?(String)
      attributes[:previous_references] = attributes[:previous_references].split(",").map(&:strip)
    end

    create_class.new(
      **attributes.merge(local_authority:)
    ).perform
  end

  def create_tempfile
    @file = Tempfile.new([filename_prefix.underscore, ".csv"])
    write_tempfile(@file)
    @file.close
  end

  def write_tempfile(file)
    if local_import_file_enabled?
      Rails.logger.debug "Using local file for import"
      file.write(local_import_file)
    else
      s3.get_object(bucket: "bops-#{Bops.env}-import", key: s3_key) do |chunk|
        file.write(chunk.dup.force_encoding("utf-8"))
      end
    end
  end

  def local_import_file
    Rails.root.join("tmp", filename).read
  end

  def filename
    "#{filename_prefix}#{local_authority_name.capitalize}.csv"
  end

  def s3_key
    "#{filename_prefix.underscore}/#{filename}"
  end

  def filename_prefix
    {
      "UsersCreation" => "Users",
      "PlanningApplicationsCreation" => "SiteHistory",
      "SiteNoticesCreation" => "SiteNotices"
    }.fetch(create_class_name.to_s) do
      raise "Unknown create_class_name: #{create_class_name}"
    end
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
