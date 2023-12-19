# frozen_string_literal: true

require "optparse"

namespace :local_authority do |args|
  desc "Creates local authority with given name: rake local_authority:create"
  # environment is required to have access to Rails models
  task create: :environment do |_task|
    broadcast "LocalAuthority: #{LocalAuthority.count}"

    options = {}
    opts = OptionParser.new
    opts.banner = "Usage: rake local_authority:create [options]"
    opts.on("-sd", "--subdomain ARG", String) { |subdomain| options[:subdomain] = subdomain }
    opts.on("-cc", "--council_code ARG", String) { |council_code| options[:council_code] = council_code }
    opts.on("-sc", "--short_name ARG", String) { |short_name| options[:short_name] = short_name }
    opts.on("-cn", "--council_name ARG", String) { |council_name| options[:council_name] = council_name }
    opts.on("-au", "--applicants_url ARG", String) { |applicants_url| options[:applicants_url] = applicants_url }
    opts.on("-ae", "--admin_email ARG", String) { |admin_email| options[:admin_email] = admin_email }

    args = opts.order!(ARGV) {} # rubocop:disable Lint/EmptyBlock
    opts.parse!(args)

    broadcast "Creating local_authority: #{options[:subdomain]}"

    LocalAuthorityCreationService.new(options).call

    broadcast "LocalAuthority: #{LocalAuthority.count}"
    broadcast "End"
  end

  def broadcast(message)
    puts message
    Rails.logger.info message
  end
end
